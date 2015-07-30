#include "MLC_ILogCore.h"
#include "MLC_PluginHelper.h"
#include <pthread.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sys/time.h>
#include <unistd.h>

#ifdef __linux__
#   include <syscall.h>
#endif

#if defined(__linux__)
#   include <sys/resource.h>
#   include <sys/wait.h>
#elif defined(__MACH__)
#   include <mach/mach_init.h>
#   include <mach/thread_act.h>
#   include <mach/mach_port.h>
#endif

static int mThreads = 1;
static int mCount = 1;
static int mRead = 0;
static int mSleep = 0;
static MLC_ILogCore * log = NULL;

class TestPlugin : public MLC_PluginHelper<MLC_IPlugin>
{
    MLC_DECL_PLUGIN(TestPlugin)

public:
    TestPlugin(MLC_ILogCore *core) : super_type(core) {
    }
    virtual ~TestPlugin() {}

    virtual int priority() const
    {
        return MLC_ILogCore::kPriorityNoop;
    }

    /**
     * They're called when the plugin is activated/deactivated. Here 
     */
    virtual void onActivate(const char * val)
    {
        super_type::onActivate(val);

        registerObserver("threads");
        registerObserver("count");
        registerObserver("read");
        registerObserver("sleep");
    }

    virtual void onDeactivate(const char * val)
    {
        unregisterObserver("threads");
        unregisterObserver("count");
        unregisterObserver("read");
        unregisterObserver("sleep");

        super_type::onDeactivate(val);
    }

    virtual void onChanged(const char * name, const char* oldval, const char* newval)
    {
        if (0 == strcmp(name, "threads")) {
            if (newval) {
                mThreads = strtol(newval, NULL, 0);
            }
        }
        else if (0 == strcmp(name, "count")) {
            if (newval) {
                mCount = strtol(newval, NULL, 0);
            }
        }
        else if (0 == strcmp(name, "read")) {
            if (newval) {
                mRead = strtol(newval, NULL, 0);
            }
        }
        else if (0 == strcmp(name, "sleep")) {
            if (newval) {
                mSleep = strtol(newval, NULL, 0);
            }
        }
    }
};

static void output(MLC_ILogCore::LogLevel level, const char* tag, const char* format, ...)
{
    va_list va;
    va_start(va, format);
    log->output(level, tag, format, va);
    va_end(va);
}

#if defined(__APPLE__)
static unsigned int gettid(void)
{
    uint64_t tid;
    pthread_t curThread = pthread_self();
    pthread_threadid_np(curThread, &tid);
    return tid;
}
#elif defined(__linux__)
pid_t gettid()
{
    return syscall(__NR_gettid);
}
#endif


struct thread_time {
    timeval usr;
    timeval sys;
};


void get_thread_time(thread_time* time)
{
#if defined(__linux__)
    rusage info;
    getrusage(RUSAGE_THREAD, &info);
    memcpy(&(time->usr), &(info.ru_utime), sizeof(time->usr));
    memcpy(&(time->sys), &(info.ru_stime), sizeof(time->sys));
#elif defined(__MACH__)
    thread_port_t thread = mach_thread_self();
    mach_msg_type_number_t count = THREAD_BASIC_INFO_COUNT;
    thread_basic_info_data_t info;
    int kr = thread_info(thread, THREAD_BASIC_INFO, (thread_info_t) &info, &count);
    mach_port_deallocate(mach_task_self(), thread);

    if (kr != KERN_SUCCESS) {
        memset(time, 0, sizeof(*time));
        return;
    }
    
    time->usr.tv_sec = info.user_time.seconds;
    time->usr.tv_usec = info.user_time.microseconds;
    time->sys.tv_sec = info.system_time.seconds;
    time->sys.tv_usec = info.system_time.microseconds;
#endif
}

void* thread_routine(void*)
{
    timeval tm1, tm2;
    gettimeofday(&tm1, NULL);

    thread_time tm3, tm4;
    get_thread_time(&tm3);

    pid_t pid = getpid();
    int i = 0;
    for ( ; i < mCount; ++i) {
        output(MLC_ILogCore::kLevelDebug, "Navi", "Hello, it's a simple test: %d @ pid %d", i, pid);
    }

    get_thread_time(&tm4);

    gettimeofday(&tm2, NULL);
    printf("Output %d record(s) costs us %ld us (%ld ms: user = %ld ms, sys = %ld ms) @ thread %d, process %d\n",
        mCount,
        (tm2.tv_sec - tm1.tv_sec) * 1000000 + tm2.tv_usec - tm1.tv_usec,
        (tm2.tv_sec - tm1.tv_sec) * 1000 + (tm2.tv_usec - tm1.tv_usec) / 1000,
        (tm4.usr.tv_sec - tm3.usr.tv_sec) * 1000 + (tm4.usr.tv_usec - tm3.usr.tv_usec) / 1000,
        (tm4.sys.tv_sec - tm3.sys.tv_sec) * 1000 + (tm4.sys.tv_usec - tm3.sys.tv_usec) / 1000,
        gettid(), pid
        );

    return NULL;
}

void* thread_routine2(void*)
{
    int i = 0;
    char buffer[1024 * 10];

    if (mSleep) {
        usleep(mSleep);
    }

    for (; i < mRead; ++i) {
        FILE *f = fopen("../config-1.txt", "r");
        if (f) {
            size_t len = fread(buffer, 1, sizeof(buffer) - 1, f);
            buffer[len] = '\0';
    timeval tm1, tm2;
    gettimeofday(&tm1, NULL);
            printf("Parsing configuration config-1.txt\n");
            if (!log->parse(buffer)) {
                printf("Illegal configuration file detected.\n");
            }
    gettimeofday(&tm2, NULL);
    printf("Parsing configuration file costs us %ld us (%ld ms) @ thread %d\n",
        (tm2.tv_sec - tm1.tv_sec) * 1000000 + tm2.tv_usec - tm1.tv_usec,
        (tm2.tv_sec - tm1.tv_sec) * 1000 + (tm2.tv_usec - tm1.tv_usec) / 1000,
        gettid()
        );
            fclose(f);
        }
    }
    
    return NULL;
}

void reportCount();
int main(int argc, const char** argv)
{
	log = MLC_ILogCore::createInstance();
    log->registerPlugin("test", &TestPlugin::createInstance);

    char buffer[1024 * 10];
    FILE *f = fopen(argc > 1 ? argv[1] : "../config.txt", "r");
    if (f) {
        size_t len = fread(buffer, 1, sizeof(buffer) - 1, f);
        buffer[len] = '\0';
        if (!log->parse(buffer)) {
            printf("Illegal configuration file detected.\n");
        }
        fclose(f);
    }

    pid_t pid = fork();
    if (pid) {
	    printf("process %d created @ process %d\n", pid, getpid());
	}

    int i = 0;
    pthread_t threads[mThreads + 1];

    for (i = 0; i < mThreads; ++i) {
        pthread_create(&threads[i], NULL, &thread_routine, NULL);
    }

    pthread_create(&threads[mThreads], NULL, &thread_routine2, NULL);

    for (i = 0; i < sizeof(threads) / sizeof(threads[0]); ++i) {
        pthread_join(threads[i], NULL);
    }

    printf("%d threads finished.\n", mThreads);

    if (pid) {
        int stat_loc = 0;
        waitpid(pid, &stat_loc, 0);
        printf("child process %d ends\n", pid);
    }
    
    delete log;

    return 0;
}
