import { fileIo as fs } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;
const TAG = 'FileUtils';

/**
 * File type enumeration
 */
export enum FileType {
  HTML = 'html',
  MARKDOWN = 'markdown',
  UNKNOWN = 'unknown'
}

/**
 * File utility class for reading and processing shared files
 */
export class FileUtils {
  /**
   * Read file content from URI
   * @param uri File URI
   * @returns File content as string
   */
  static async readFileContent(uri: string): Promise<string> {
    hilog.info(DOMAIN, TAG, 'readFileContent called with URI: %{public}s', uri);
    
    try {
      // Open file from URI
      const file = fs.openSync(uri, fs.OpenMode.READ_ONLY);
      hilog.info(DOMAIN, TAG, 'File opened successfully, fd: %{public}d', file.fd);
      
      // Get file stats to determine size
      const stat = fs.statSync(file.fd);
      hilog.info(DOMAIN, TAG, 'File size: %{public}d bytes', stat.size);
      
      // Read file content
      const buffer = new ArrayBuffer(stat.size);
      const readLen = fs.readSync(file.fd, buffer);
      hilog.info(DOMAIN, TAG, 'Read %{public}d bytes from file', readLen);
      
      // Close file
      fs.closeSync(file);
      
      // Convert buffer to string (UTF-8)
      const decoder = util.TextDecoder.create('utf-8');
      const content = decoder.decodeToString(new Uint8Array(buffer));
      
      hilog.info(DOMAIN, TAG, 'File content decoded successfully, length: %{public}d', content.length);
      return content;
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to read file: %{public}s', JSON.stringify(err));
      throw new Error(`Failed to read file: ${JSON.stringify(err)}`);
    }
  }
  
  /**
   * Get file type from file name or URI
   * @param fileName File name or URI
   * @returns FileType enum value
   */
  static getFileType(fileName: string): FileType {
    const extension = FileUtils.getFileExtension(fileName).toLowerCase();
    hilog.info(DOMAIN, TAG, 'getFileExtension: %{public}s', extension);
    
    // Check for HTML files
    if (extension === 'html' || extension === 'htm') {
      return FileType.HTML;
    }
    
    // Check for Markdown files
    if (extension === 'md' || extension === 'markdown') {
      return FileType.MARKDOWN;
    }
    
    return FileType.UNKNOWN;
  }
  
  /**
   * Get file extension from file name or URI
   * @param fileName File name or URI
   * @returns File extension without dot
   */
  static getFileExtension(fileName: string): string {
    if (!fileName || fileName.length === 0) {
      return '';
    }
    
    // Remove query parameters if present (for URIs)
    let cleanFileName = fileName;
    const queryIndex = fileName.indexOf('?');
    if (queryIndex > 0) {
      cleanFileName = fileName.substring(0, queryIndex);
    }
    
    // Get last component of path
    const lastSlashIndex = cleanFileName.lastIndexOf('/');
    if (lastSlashIndex >= 0) {
      cleanFileName = cleanFileName.substring(lastSlashIndex + 1);
    }
    
    // Get extension
    const dotIndex = cleanFileName.lastIndexOf('.');
    if (dotIndex > 0 && dotIndex < cleanFileName.length - 1) {
      return cleanFileName.substring(dotIndex + 1);
    }
    
    return '';
  }
  
  /**
   * Get file name from URI
   * @param uri File URI
   * @returns File name
   */
  static getFileName(uri: string): string {
    if (!uri || uri.length === 0) {
      return '';
    }
    
    // Remove query parameters if present
    let cleanUri = uri;
    const queryIndex = uri.indexOf('?');
    if (queryIndex > 0) {
      cleanUri = uri.substring(0, queryIndex);
    }
    
    // Get last component of path
    const lastSlashIndex = cleanUri.lastIndexOf('/');
    if (lastSlashIndex >= 0 && lastSlashIndex < cleanUri.length - 1) {
      return cleanUri.substring(lastSlashIndex + 1);
    }
    
    return cleanUri;
  }
  
  /**
   * Check if UTD type indicates HTML content
   * @param utd Uniform Type Descriptor
   * @returns true if HTML type
   */
  static isHtmlUtd(utd: string): boolean {
    return utd === 'general.html' || 
           utd.includes('html') || 
           utd === 'public.html';
  }
  
  /**
   * Check if UTD type indicates Markdown content
   * @param utd Uniform Type Descriptor
   * @returns true if Markdown type
   */
  static isMarkdownUtd(utd: string): boolean {
    return utd.includes('markdown') || 
           utd === 'general.text';  // Markdown might be shared as general.text
  }
  
  /**
   * Determine file type from both extension and UTD
   * @param uri File URI
   * @param utd Uniform Type Descriptor
   * @returns FileType enum value
   */
  static determineFileType(uri: string, utd: string): FileType {
    // First try to determine by file extension
    const fileType = FileUtils.getFileType(uri);
    if (fileType !== FileType.UNKNOWN) {
      return fileType;
    }
    
    // If extension is unknown, try UTD
    if (FileUtils.isHtmlUtd(utd)) {
      return FileType.HTML;
    }
    
    if (FileUtils.isMarkdownUtd(utd)) {
      return FileType.MARKDOWN;
    }
    
    return FileType.UNKNOWN;
  }
}
