/**
 * Copyright @ 2014 - 2017 Suntec Software(Shanghai) Co., Ltd.
 * All Rights Reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are NOT permitted except as agreed by
 * Suntec Software(Shanghai) Co., Ltd.
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an AS IS BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 */

#include "stdafx.h"
#include "BL_File.h"
#include "BL_Path.h"
#include "CL_Time.h"
#include "BL_Dir.h"
#include "BL_ExternalFile.h"

BL_File::BL_File(BL_FilePrefix ePrefix)
    : m_eFilePrefix(ePrefix)
    , m_strDirEntryFileName("")
    , m_pcDir(NULL)
    , m_dwDirEntryOffset(0)
    , m_pExternalFile(NULL)
    , m_pLocalFileImpl(NULL)
{
#if defined(BL_COMP_OPT_HAVE_EXTERNAL_FILE) && BL_COMP_OPT_HAVE_EXTERNAL_FILE
    m_pExternalFile = new(MEM_Base) BL_ExternalFile(BL_REMOTE_OPEN_COPYOPEN, ePrefix);
#endif
    m_pLocalFileImpl = new(MEM_Base) CL_File_Abs();
    memset(m_szPath, 0, sizeof(m_szPath));
}

BL_File::BL_File()
    : m_eFilePrefix(BL_FILE_PREFIX_AUTO)
    , m_strDirEntryFileName("")
    , m_pcDir(NULL)
    , m_dwDirEntryOffset(0)
    , m_pExternalFile(NULL)
    , m_pLocalFileImpl(NULL)
{
#if defined(BL_COMP_OPT_HAVE_EXTERNAL_FILE) && BL_COMP_OPT_HAVE_EXTERNAL_FILE
    m_pExternalFile = new(MEM_Base) BL_ExternalFile(BL_REMOTE_OPEN_COPYOPEN, BL_FILE_PREFIX_AUTO);
#endif
    m_pLocalFileImpl = new(MEM_Base) CL_File_Abs();
    memset(m_szPath, 0, sizeof(m_szPath));
}

BL_File::~BL_File()
{
#if defined(BL_COMP_OPT_HAVE_EXTERNAL_FILE) && BL_COMP_OPT_HAVE_EXTERNAL_FILE
    if (NULL != m_pExternalFile) {
        delete m_pExternalFile;
        m_pExternalFile = NULL;
    }
#endif

    if (NULL != m_pLocalFileImpl) {
        delete m_pLocalFileImpl;
        m_pLocalFileImpl = NULL;
    }
}

CL_BOOL
BL_File::Open()
{
    return Open(BL_FILE_OPEN_MODE_RW);
}


CL_BOOL
BL_File::Close()
{
    return CloseFile();
}

CL_BOOL BL_File::CloseFile()
{
    BL_String strPath(m_szPath);
    CL_BOOL bRet = CL_FALSE;
#if defined(BL_COMP_OPT_HAVE_EXTERNAL_FILE) && BL_COMP_OPT_HAVE_EXTERNAL_FILE
    if (strPath.GetLength() > 0 && !BL_Path::IsLocalPath(m_szPath) && m_pExternalFile) {
        bRet = m_pExternalFile->Close();
    }
#endif
    if (m_pLocalFileImpl)
    {
        bRet = m_pLocalFileImpl->Close();
    }

    return bRet;
    
}

CL_BOOL
BL_File::Open(BL_FileOpenMode eMode)
{
    BL_String strPath(m_szPath);
#if defined(BL_COMP_OPT_HAVE_EXTERNAL_FILE) && BL_COMP_OPT_HAVE_EXTERNAL_FILE
    if (strPath.GetLength() > 0 && !BL_Path::IsLocalPath(m_szPath) && m_pExternalFile) {
        LPCTSTR pRemoteFileName = BL_Path::GetRemoteFileName(m_szPath);
        return m_pExternalFile->Open(m_eFilePrefix, pRemoteFileName, eMode);
    }
#endif
    INT iOpenMode = GetFileOpenMode(eMode);
    if (m_pLocalFileImpl) {
        return m_pLocalFileImpl->Open(m_szPath, iOpenMode);
    }
    return CL_FALSE;
    
}

CL_BOOL
BL_File::Open(const BL_String& strFileName, BL_FileOpenMode eMode, CL_BOOL bShared)
{
    return OpenInternal(strFileName, eMode, bShared);
}

CL_BOOL
BL_File::OpenInternal(const BL_String& strFileName, BL_FileOpenMode eMode,  CL_BOOL bShared)
{
    INT iOpenMode = GetFileOpenMode(eMode);
    if (bShared) {
        iOpenMode = iOpenMode | CL_FILE_OPEN_MODE_SH;
    }
    if (BL_Path::GetAbsolutePath(m_eFilePrefix, strFileName, m_szPath))
    {
#if defined(BL_COMP_OPT_HAVE_EXTERNAL_FILE) && BL_COMP_OPT_HAVE_EXTERNAL_FILE
        if (!BL_Path::IsLocalPath(m_szPath) && m_pExternalFile) {
            return m_pExternalFile->Open(m_eFilePrefix, strFileName, eMode);
        }
#endif
        // open file directly
        if (m_pLocalFileImpl) {
            return m_pLocalFileImpl->Open(m_szPath, iOpenMode);
        }
        
    }
    return CL_FALSE;
}

CL_BOOL
BL_File::Write(const VOID* pData, DWORD dwSize, DWORD *pdwLength)
{
#if defined(BL_COMP_OPT_HAVE_EXTERNAL_FILE) && BL_COMP_OPT_HAVE_EXTERNAL_FILE
    if (!BL_Path::IsLocalPath(m_szPath) && m_pExternalFile) {
        return m_pExternalFile->Write(pData, dwSize, (BL_AbstractFile::FileSize*)pdwLength);
    }
#endif

    WriteFileFunctor cFunc(this);
    if (NULL == pdwLength)
    {
        DWORD dwTempLength = 0;
        if (!DividFuncCall(pData, dwSize, dwTempLength, cFunc))
        {
            return CL_FALSE;
        }

        if (dwSize != dwTempLength)
        {
            // m_ErrorCode = APL_ERR_BL_FILE_ACTUAL_SIZE;
            return CL_FALSE;
        }

        return CL_TRUE;
    }
    else
    {
        return DividFuncCall(pData, dwSize, *pdwLength, cFunc);
    }
}

CL_BOOL
BL_File::Write(const VOID* pData, DWORD dwSize, DWORD dwCount)
{
#if defined(BL_COMP_OPT_HAVE_EXTERNAL_FILE) && BL_COMP_OPT_HAVE_EXTERNAL_FILE
    if (!BL_Path::IsLocalPath(m_szPath) && m_pExternalFile) {
        return m_pExternalFile->Write(pData, dwSize, dwCount);
    }
#endif

    DWORD dwTempLength = 0;
    WriteFileFunctor cFunc(this);
    if (!DividFuncCall(pData, dwSize*dwCount, dwTempLength, cFunc))
    {
        return CL_FALSE;
    }

    if (dwSize * dwCount != dwTempLength)
    {
        // m_ErrorCode = APL_ERR_BL_FILE_ACTUAL_SIZE;
        return CL_FALSE;
    }

    return CL_TRUE;
}

CL_BOOL
BL_File::WriteNonDivision(const VOID* pWriteBuff, DWORD dwSize, DWORD *pdwLength)
{
#if defined(BL_COMP_OPT_HAVE_EXTERNAL_FILE) && BL_COMP_OPT_HAVE_EXTERNAL_FILE
    if (!BL_Path::IsLocalPath(m_szPath) && m_pExternalFile) {
        return m_pExternalFile->Write(pWriteBuff, dwSize, (BL_AbstractFile::FileSize*)pdwLength);
    }
#endif

    if (NULL == pdwLength)
    {
        DWORD dwTempLength = 0;
        if (!WriteLocalInternal(pWriteBuff, dwSize, dwTempLength))
        {
            return CL_FALSE;
        }

        if (dwSize != dwTempLength)
        {
            // m_ErrorCode = APL_ERR_BL_FILE_ACTUAL_SIZE;
            return CL_FALSE;
        }

        return CL_TRUE;
    }
    else
    {
        return WriteLocalInternal(pWriteBuff, dwSize, *pdwLength);
    }
}

CL_BOOL BL_File::Seek(LONG lOffset, LONG lStart)
{
#if defined(BL_COMP_OPT_HAVE_EXTERNAL_FILE) && BL_COMP_OPT_HAVE_EXTERNAL_FILE
    if (!BL_Path::IsLocalPath(m_szPath) && m_pExternalFile) {
        return m_pExternalFile->Seek(lOffset, (BL_FileSeekOrigin)lStart);
    }
#endif

    if (m_pLocalFileImpl) {
        return m_pLocalFileImpl->Seek(lOffset, lStart);
    }
    return CL_FALSE;
}

CL_BOOL BL_File::Seek(DWORD dwOffset, LONG lStart, CL_BOOL bDirection)
{
#if defined(BL_COMP_OPT_HAVE_EXTERNAL_FILE) && BL_COMP_OPT_HAVE_EXTERNAL_FILE
    if (!BL_Path::IsLocalPath(m_szPath) && m_pExternalFile) {
        // remote file no bDirection seek
        return CL_FALSE;
    }
#endif

    if (m_pLocalFileImpl) {
        return m_pLocalFileImpl->Seek(dwOffset, lStart, bDirection);
    }
    return CL_FALSE;
}

CL_BOOL BL_File::IsOpen()
{
#if defined(BL_COMP_OPT_HAVE_EXTERNAL_FILE) && BL_COMP_OPT_HAVE_EXTERNAL_FILE
    if (!BL_Path::IsLocalPath(m_szPath) && m_pExternalFile) {
        return m_pExternalFile->IsOpen();
    }
#endif

    if (m_pLocalFileImpl) {
        return m_pLocalFileImpl->IsOpen();
    }
    return CL_FALSE;
}

CL_BOOL
BL_File::Read(VOID* pReadBuff, DWORD dwSize, DWORD* pdwLength)
{
#if defined(BL_COMP_OPT_HAVE_EXTERNAL_FILE) && BL_COMP_OPT_HAVE_EXTERNAL_FILE
    if (!BL_Path::IsLocalPath(m_szPath) && m_pExternalFile) {
        return m_pExternalFile->Read(pReadBuff, dwSize, (BL_AbstractFile::FileSize*)pdwLength);
    }
#endif

    ReadFileFunctor cFunctor(this);
    if (NULL == pdwLength) {
        DWORD dwTempLength = 0;
        if (!DividFuncCall(pReadBuff, dwSize, dwTempLength, cFunctor)) {
            return CL_FALSE;
        }

        if (dwSize != dwTempLength) {
            // m_ErrorCode = APL_ERR_BL_FILE_ACTUAL_SIZE;
            return CL_FALSE;
        }
        return CL_TRUE;
    }
    else {
        return DividFuncCall(pReadBuff, dwSize, *pdwLength, cFunctor);
    }
}

CL_BOOL
BL_File::Read(VOID* pReadBuff, DWORD dwSize, DWORD dwCount)
{
#if defined(BL_COMP_OPT_HAVE_EXTERNAL_FILE) && BL_COMP_OPT_HAVE_EXTERNAL_FILE
    if (!BL_Path::IsLocalPath(m_szPath) && m_pExternalFile) {
        return m_pExternalFile->Read(pReadBuff, dwSize, dwCount);
    }
#endif

    DWORD dwTempLength = 0;
    ReadFileFunctor cFunctor(this);
    if (!DividFuncCall(pReadBuff, dwSize * dwCount, dwTempLength, cFunctor)) {
        return CL_FALSE;
    }

    if (dwSize * dwCount != dwTempLength) {
        // m_ErrorCode = APL_ERR_BL_FILE_ACTUAL_SIZE;
        return CL_FALSE;
    }

    return CL_TRUE;
}

CL_BOOL
BL_File::ReadNonDivision(VOID* pReadBuff, DWORD dwSize, DWORD* pdwLength)
{
#if defined(BL_COMP_OPT_HAVE_EXTERNAL_FILE) && BL_COMP_OPT_HAVE_EXTERNAL_FILE
    if (!BL_Path::IsLocalPath(m_szPath) && m_pExternalFile) {
        return m_pExternalFile->Read(pReadBuff, dwSize, (BL_AbstractFile::FileSize*)pdwLength);
    }
#endif

    if (NULL == pdwLength) {
        DWORD dwTempLength = 0;
        if (!ReadLocalInternal(pReadBuff, dwSize, dwTempLength)) {
            return CL_FALSE;
        }

        if (dwSize != dwTempLength) {
            // m_ErrorCode = APL_ERR_BL_FILE_ACTUAL_SIZE;
            return CL_FALSE;
        }

        return CL_TRUE;
    }
    else {
        return ReadLocalInternal(pReadBuff, dwSize, *pdwLength);
    }
}

CL_BOOL BL_File::ReadLocalInternal(VOID* pReadBuff, const DWORD dwSize, DWORD& dwLength)
{
    if (m_pLocalFileImpl) {
        return m_pLocalFileImpl->Read(pReadBuff, dwSize, &dwLength);
    }
    return CL_FALSE;
}

CL_BOOL BL_File::WriteLocalInternal(const VOID* pData, DWORD dwSize, DWORD& dwlength)
{
    if (m_pLocalFileImpl) {
        return m_pLocalFileImpl->Write(pData, dwSize, &dwlength);
    }
    return CL_FALSE;
}

CL_BOOL
BL_File::RemoveFile(const BL_String& strFileName)
{
    TCHAR  szPath[MAX_PATH + 1] = { 0 };
    if (BL_Path::GetAbsolutePath(m_eFilePrefix, strFileName, szPath)) {
#if defined(BL_COMP_OPT_HAVE_EXTERNAL_FILE) && BL_COMP_OPT_HAVE_EXTERNAL_FILE
        if (!BL_Path::IsLocalPath(szPath) && m_pExternalFile) {
            // remote file not support remove
            return CL_FALSE;
        }
#endif
        if (m_pLocalFileImpl) {
            return m_pLocalFileImpl->Delete(szPath);
        }
    }

    return CL_FALSE;
}

CL_BOOL
BL_File::IsFileExist(const BL_String& strFileName)
{
    TCHAR  szPath[MAX_PATH + 1] = { 0 };
    if (BL_Path::GetAbsolutePath(m_eFilePrefix, strFileName, szPath)) {
#if defined(BL_COMP_OPT_HAVE_EXTERNAL_FILE) && BL_COMP_OPT_HAVE_EXTERNAL_FILE
        if (!BL_Path::IsLocalPath(szPath) && m_pExternalFile) {
            return m_pExternalFile->FileExists(strFileName);
        }
#endif
        if (m_pLocalFileImpl) {
            return m_pLocalFileImpl->IsFileExist(szPath);
        }
    }

    return CL_FALSE;
}

DWORD
BL_File::GetFileAttribute(const BL_String& strFileName)
{
    TCHAR  szPath[MAX_PATH + 1] = { 0 };
    if (BL_Path::GetAbsolutePath(m_eFilePrefix, strFileName, szPath))
    {
        if (BL_Path::IsLocalPath(szPath)) {
            if (m_pLocalFileImpl) {
                return m_pLocalFileImpl->GetFileAttribute(szPath);
            }
        }
    }

    return -1;
}

CL_BOOL
BL_File::SetFileAttribute(const BL_String& strFileName, DWORD dwAttribute)
{
    TCHAR  szPath[MAX_PATH + 1] = { 0 };
    if (BL_Path::GetAbsolutePath(m_eFilePrefix, strFileName, szPath))
    {
        if (BL_Path::IsLocalPath(szPath)) {
            if (m_pLocalFileImpl) {
                return m_pLocalFileImpl->SetFileAttribute(szPath, dwAttribute);
            }
        }
    }
    return CL_FALSE;
}

CL_BOOL
BL_File::GetFileTime(const BL_String& strFileName, CL_Time* pcFileTime)
{
    TCHAR  szPath[MAX_PATH + 1] = { 0 };
    if (BL_Path::GetAbsolutePath(m_eFilePrefix, strFileName, szPath)) {
#if defined(BL_COMP_OPT_HAVE_EXTERNAL_FILE) && BL_COMP_OPT_HAVE_EXTERNAL_FILE
        if (!BL_Path::IsLocalPath(szPath) && m_pExternalFile) {
            return m_pExternalFile->GetFileTime(strFileName, pcFileTime);
        }
#endif
        if (m_pLocalFileImpl) {
            return m_pLocalFileImpl->GetFileTime(szPath, pcFileTime);
        }
    }
    return CL_FALSE;
}

CL_BOOL
BL_File::SetFileTime(const BL_String& strFileName, const CL_Time* pcFileTime)
{
    TCHAR  szPath[MAX_PATH + 1] = { 0 };
    if (BL_Path::GetAbsolutePath(m_eFilePrefix, strFileName, szPath))
    {
        if (BL_Path::IsLocalPath(szPath)) {
            if (m_pLocalFileImpl) {
                return m_pLocalFileImpl->SetFileTime(szPath, pcFileTime);
            }
        }
    }
    return CL_FALSE;
}

LONG
BL_File::GetFileSize(const BL_String& strFileName)
{
    TCHAR  szPath[MAX_PATH + 1] = { 0 };
    if (BL_Path::GetAbsolutePath(m_eFilePrefix, strFileName, szPath)) {
#if defined(BL_COMP_OPT_HAVE_EXTERNAL_FILE) && BL_COMP_OPT_HAVE_EXTERNAL_FILE
        if (!BL_Path::IsLocalPath(szPath) && m_pExternalFile) {
            if (m_pExternalFile->Open(strFileName, BL_FILE_OPEN_MODE_R)) {
                LONG nRet = m_pExternalFile->GetFileSize();
                m_pExternalFile->Close();
                return nRet;
            }
            else {
                return BL_FILE_INVALID_SIZE;
            }
        }
#endif
        if (m_pLocalFileImpl) {
            return m_pLocalFileImpl->GetFileSize(szPath);
        }
    }
    return BL_FILE_INVALID_SIZE;
}

DWORD
BL_File::GetFileSizeInfo(const BL_String& strFileName)
{
    TCHAR  szPath[MAX_PATH + 1] = { 0 };
    if (BL_Path::GetAbsolutePath(m_eFilePrefix, strFileName, szPath)) {
#if defined(BL_COMP_OPT_HAVE_EXTERNAL_FILE) && BL_COMP_OPT_HAVE_EXTERNAL_FILE
        if (!BL_Path::IsLocalPath(szPath) && m_pExternalFile) {
            if (m_pExternalFile->Open(strFileName, BL_FILE_OPEN_MODE_R)) {
                LONG nRet = m_pExternalFile->GetFileSize();
                m_pExternalFile->Close();
                return nRet;
            }
            else {
                return BL_FILE_INVALID_SIZE;
            }
        }
#endif
        if (m_pLocalFileImpl) {
            return m_pLocalFileImpl->GetFileSizeInfo(szPath);
        }
    }
    return BL_FILE_INVALID_SIZE;
}

LONG
BL_File::GetFileSize()
{
#if defined(BL_COMP_OPT_HAVE_EXTERNAL_FILE) && BL_COMP_OPT_HAVE_EXTERNAL_FILE
    if (!BL_Path::IsLocalPath(m_szPath) && m_pExternalFile) {
        return m_pExternalFile->GetFileSize();
    }
#endif
    if (m_pLocalFileImpl) {
        return m_pLocalFileImpl->GetFileSize();
    }
    return BL_FILE_INVALID_SIZE;
}

CL_BOOL
BL_File::GetAbsolutePath(const BL_String& strFileName, BL_String& strFilePath) const
{
    NCHAR szFilePath[MAX_PATH+1];
    memset(szFilePath, 0, sizeof(szFilePath));
    strFilePath.GetString(szFilePath, MAX_PATH);

    if(BL_Path::GetAbsolutePath(m_eFilePrefix, strFileName, szFilePath))
    {   //Fetch the physical path
        strFilePath.Set(szFilePath);
        return CL_TRUE;
    }

    return CL_FALSE;
}

CL_BOOL
BL_File::Rename(const CL_String& strOldName, const CL_String& strNewName)
{
    BL_String strOldPath ("");
    BL_String strNewPath ("");
     if (GetAbsolutePath (strOldName, strOldPath) && GetAbsolutePath (strNewName, strNewPath)) {
        if (!BL_Path::IsLocalPath(strOldPath.GetString()) || !BL_Path::IsLocalPath(strNewPath.GetString())) {
            // remote not support rename
            return CL_FALSE;
        }
        if (m_pLocalFileImpl) {
            return m_pLocalFileImpl->Rename(strOldPath, strNewPath);
        }
    }

    return CL_FALSE;
}

DWORD BL_File::GetErrorCode()
{
#if defined(BL_COMP_OPT_HAVE_EXTERNAL_FILE) && BL_COMP_OPT_HAVE_EXTERNAL_FILE
    if (!BL_Path::IsLocalPath(m_szPath) && m_pExternalFile) {
        return m_pExternalFile->GetErrorCode();
    }
#endif
    if (m_pLocalFileImpl) {
        return m_pLocalFileImpl->GetErrorCode();
    }
    return CL_ERROR_FILE_NOERROR;
}

CL_BOOL BL_File::SetEndOfFile()
{
    if (BL_Path::IsLocalPath(m_szPath) && m_pLocalFileImpl) {
        return m_pLocalFileImpl->SetEndOfFile();
    }
    // remote file can't be truncated ,so return false 
    return CL_FALSE;
}

LPTSTR BL_File::Gets(LPTSTR pszStr, INT nGets)
{
    if (BL_Path::IsLocalPath(m_szPath) && m_pLocalFileImpl) {
        return m_pLocalFileImpl->Gets(pszStr, nGets);
    }
    // remote file , no  Gets interfaces ,return NULL 
    return NULL;
}

CL_BOOL BL_File::Flush()
{
    if (BL_Path::IsLocalPath(m_szPath) && m_pLocalFileImpl) {
        return m_pLocalFileImpl->Flush();
    }
    // externalfile no flush interface
    return CL_FALSE;
}

INT
BL_File::GetFileOpenMode(BL_FileOpenMode eMode)
{
    INT iMode;
    switch (eMode)
    {
        case BL_FILE_OPEN_MODE_RW:
            iMode = CL_FILE_OPEN_MODE_RW;
            break;
        case BL_FILE_OPEN_MODE_R:
            iMode = CL_FILE_OPEN_MODE_R;
            break;
        case BL_FILE_OPEN_MODE_RP:
            iMode = CL_FILE_OPEN_MODE_RP;
            break;
        case BL_FILE_OPEN_MODE_W:
            iMode = CL_FILE_OPEN_MODE_W;
            break;
        case BL_FILE_OPEN_MODE_WP:
            iMode = CL_FILE_OPEN_MODE_WP;
            break;
        case BL_FILE_OPEN_MODE_A:
            iMode = CL_FILE_OPEN_MODE_A;
            break;
        case BL_FILE_OPEN_MODE_AP:
            iMode = CL_FILE_OPEN_MODE_AP;
            break;
        default:
            iMode = CL_FILE_OPEN_MODE_R;
    }
    return iMode;
}

BL_File::ReadFileFunctor::ReadFileFunctor(BL_File *pFile)
:m_pFile(pFile)
{
}

BL_File::ReadFileFunctor::~ReadFileFunctor()
{
    m_pFile = NULL;
}

CL_BOOL
BL_File::ReadFileFunctor::operator()(pointer pData, DWORD dwSize, DWORD& dwLength) const
{
    return m_pFile->ReadLocalInternal(pData, dwSize, dwLength);
}

BL_File::WriteFileFunctor::WriteFileFunctor(BL_File *pFile)
:m_pFile(pFile)
{
}

BL_File::WriteFileFunctor::~WriteFileFunctor()
{
    m_pFile = NULL;
}

CL_BOOL
BL_File::WriteFileFunctor::operator()(pointer pData, DWORD dwSize, DWORD& dwLength)
{
    return m_pFile->WriteLocalInternal(pData, dwSize, dwLength);
}