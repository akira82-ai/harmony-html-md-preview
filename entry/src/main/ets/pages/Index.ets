import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { FileUtils, FileType } from '../utils/FileUtils';
import { resourceManager } from '@kit.LocalizationKit';
import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';

const DOMAIN = 0x0000;
const TAG = 'IndexPage';

// Test file definition
interface TestFile {
  name: string;
  fileName: string;
  type: FileType;
  icon: string;
}

@Entry
@Component
struct Index {
  @State hasSharedData: boolean = false;
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  @State showTestFiles: boolean = false;
  @StorageLink('sharedFileUri') @Watch('onSharedDataChanged') sharedFileUri: string = '';
  @StorageLink('sharedFileUtd') sharedFileUtd: string = '';
  @StorageLink('hasSharedData') @Watch('onSharedDataChanged') storageHasSharedData: boolean = false;
  
  // Watch callback for shared data changes
  onSharedDataChanged(): void {
    hilog.info(DOMAIN, TAG, 'Shared data changed - URI: %{public}s, hasData: %{public}s', 
      this.sharedFileUri, this.storageHasSharedData.toString());
    
    if (this.storageHasSharedData && this.sharedFileUri.length > 0 && !this.hasSharedData) {
      this.hasSharedData = true;
      this.processSharedFile();
    }
  }
  
  // Test files list
  private testFiles: TestFile[] = [
    { name: '简单 HTML', fileName: 'simple.html', type: FileType.HTML, icon: '🌐' },
    { name: '复杂 HTML', fileName: 'rich.html', type: FileType.HTML, icon: '🎨' },
    { name: '中文 HTML', fileName: 'chinese.html', type: FileType.HTML, icon: '🇨🇳' },
    { name: '桌面宠物', fileName: 'new.html', type: FileType.HTML, icon: '🐔' },
    { name: '基础 Markdown', fileName: 'basic.md', type: FileType.MARKDOWN, icon: '📝' },
    { name: '高级 Markdown', fileName: 'advanced.md', type: FileType.MARKDOWN, icon: '🚀' },
    { name: '混合内容', fileName: 'mixed.md', type: FileType.MARKDOWN, icon: '🔀' }
  ];

  aboutToAppear(): void {
    hilog.info(DOMAIN, TAG, 'Index page aboutToAppear');
    hilog.info(DOMAIN, TAG, 'hasSharedData: %{public}s', this.storageHasSharedData.toString());
    hilog.info(DOMAIN, TAG, 'sharedFileUri: %{public}s', this.sharedFileUri);
    hilog.info(DOMAIN, TAG, 'sharedFileUtd: %{public}s', this.sharedFileUtd);

    // Check if there's shared data immediately (data might already be set)
    if (this.storageHasSharedData && this.sharedFileUri.length > 0) {
      hilog.info(DOMAIN, TAG, 'Found shared data immediately, processing...');
      this.hasSharedData = true;
      this.processSharedFile();
    } else {
      // Returning from Viewer — reset local state to show WelcomeView
      this.hasSharedData = false;
      this.isLoading = false;
      this.errorMessage = '';
    }
    // Otherwise, wait for @Watch callback to trigger when data arrives
  }

  /**
   * Clear shared data from AppStorage to prevent re-processing when returning to Index
   */
  private clearSharedData(): void {
    hilog.info(DOMAIN, TAG, 'Clearing shared data from AppStorage');
    AppStorage.setOrCreate('hasSharedData', false);
    AppStorage.setOrCreate('sharedFileUri', '');
    AppStorage.setOrCreate('sharedFileUtd', '');
    this.hasSharedData = false;
  }

  /**
   * Process the shared file
   */
  private async processSharedFile(): Promise<void> {
    hilog.info(DOMAIN, TAG, 'Processing shared file');
    this.isLoading = true;
    this.errorMessage = '';
    
    try {
      // Determine file type
      const fileType = FileUtils.determineFileType(this.sharedFileUri, this.sharedFileUtd);
      hilog.info(DOMAIN, TAG, 'Determined file type: %{public}s', fileType);
      
      // Read file content
      const content = await FileUtils.readFileContent(this.sharedFileUri);
      hilog.info(DOMAIN, TAG, 'File content read successfully, length: %{public}d', content.length);
      
      // Get file name
      const fileName = FileUtils.getFileName(this.sharedFileUri);
      hilog.info(DOMAIN, TAG, 'File name: %{public}s', fileName);
      
      // Navigate to appropriate viewer
      this.isLoading = false;

      if (fileType === FileType.HTML) {
        hilog.info(DOMAIN, TAG, 'Navigating to HTML viewer');
        router.pushUrl({
          url: 'pages/HtmlViewer',
          params: {
            content: content,
            fileName: fileName
          }
        });
      } else if (fileType === FileType.MARKDOWN) {
        hilog.info(DOMAIN, TAG, 'Navigating to Markdown viewer');
        router.pushUrl({
          url: 'pages/MarkdownViewer',
          params: {
            content: content,
            fileName: fileName
          }
        });
      } else {
        hilog.error(DOMAIN, TAG, 'Unsupported file type: %{public}s', fileType);
        this.errorMessage = 'Unsupported file type. Please share an HTML or Markdown file.';
        return;
      }

      // Clear shared data so returning to Index shows WelcomeView instead of re-processing
      this.clearSharedData();
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to process shared file: %{public}s', JSON.stringify(err));
      this.isLoading = false;
      this.errorMessage = 'Failed to load file. Please try again.';
    }
  }

  build() {
    Column() {
      if (this.isLoading) {
        this.LoadingView();
      } else if (this.errorMessage.length > 0) {
        this.ErrorView();
      } else if (this.hasSharedData) {
        this.ProcessingView();
      } else if (this.showTestFiles) {
        this.TestFilesView();
      } else {
        this.WelcomeView();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  LoadingView() {
    Column() {
      LoadingProgress()
        .width(64)
        .height(64)
        .color('#007DFF')
      
      Text('Loading file...')
        .fontSize(16)
        .fontColor('#333333')
        .margin({ top: 24 })
      
      Text('Please wait while we process the shared file')
        .fontSize(14)
        .fontColor('#999999')
        .margin({ top: 8 })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  ErrorView() {
    Column() {
      Image($r('sys.media.ohos_ic_public_fail'))
        .width(64)
        .height(64)
        .fillColor('#FF0000')
      
      Text('Error')
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .margin({ top: 24 })
      
      Text(this.errorMessage)
        .fontSize(14)
        .fontColor('#999999')
        .margin({ top: 8 })
        .textAlign(TextAlign.Center)
        .padding({ left: 32, right: 32 })
      
      Button('Try Again')
        .fontSize(16)
        .fontColor('#FFFFFF')
        .backgroundColor('#007DFF')
        .borderRadius(8)
        .height(44)
        .width(160)
        .margin({ top: 32 })
        .onClick(() => {
          if (this.sharedFileUri.length > 0) {
            this.processSharedFile();
          }
        })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  ProcessingView() {
    Column() {
      LoadingProgress()
        .width(64)
        .height(64)
        .color('#007DFF')
      
      Text('Processing shared file...')
        .fontSize(16)
        .fontColor('#333333')
        .margin({ top: 24 })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  WelcomeView() {
    Column() {
      // Icon
      Text('📄')
        .fontSize(60)
        .fontColor('#007DFF')
      
      // Title
      Text('File Viewer')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .margin({ top: 32 })
      
      // Description
      Text('View HTML and Markdown files shared from other apps')
        .fontSize(16)
        .fontColor('#666666')
        .margin({ top: 16 })
        .textAlign(TextAlign.Center)
        .padding({ left: 48, right: 48 })
      
      // Test Button
      Button('🧪 测试文件')
        .fontSize(16)
        .fontColor('#FFFFFF')
        .backgroundColor('#10AEFF')
        .borderRadius(8)
        .height(44)
        .width(200)
        .margin({ top: 32 })
        .onClick(() => {
          this.showTestFiles = true;
        })
      
      // Instructions
      Column() {
        this.InstructionItem('1', 'Open any app with files (e.g., File Manager)')
        this.InstructionItem('2', 'Select an HTML or Markdown file')
        this.InstructionItem('3', 'Tap Share and select File Viewer')
      }
      .width('100%')
      .margin({ top: 32 })
      .padding({ left: 32, right: 32 })
      
      // Supported formats
      Column() {
        Text('Supported Formats')
          .fontSize(14)
          .fontColor('#999999')
          .margin({ bottom: 8 })
        
        Row() {
          this.FormatBadge('HTML')
          this.FormatBadge('Markdown')
        }
      }
      .margin({ top: 32 })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding({ top: 48, bottom: 48 })
  }

  @Builder
  InstructionItem(number: string, text: string) {
    Row() {
      Text(number)
        .fontSize(14)
        .fontColor('#FFFFFF')
        .width(28)
        .height(28)
        .textAlign(TextAlign.Center)
        .borderRadius(14)
        .backgroundColor('#007DFF')
      
      Text(text)
        .fontSize(14)
        .fontColor('#666666')
        .margin({ left: 12 })
        .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .margin({ bottom: 16 })
  }

  @Builder
  FormatBadge(format: string) {
    Text(format)
      .fontSize(12)
      .fontColor('#007DFF')
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .borderRadius(4)
      .backgroundColor('#E3F2FD')
      .margin({ left: 6, right: 6 })
  }
  
  @Builder
  TestFilesView() {
    Column() {
      // Header
      Row() {
        Button('← 返回')
          .fontSize(16)
          .fontColor('#007DFF')
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.showTestFiles = false;
          })
        
        Blank()
        
        Text('测试文件')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
        
        Blank()
        
        Button('← 返回')
          .fontSize(16)
          .fontColor('#007DFF')
          .backgroundColor(Color.Transparent)
          .visibility(Visibility.Hidden)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })
      
      // Description
      Text('选择一个测试文件来验证渲染功能')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ top: 8, bottom: 16 })
      
      // Test files list
      List() {
        ForEach(this.testFiles, (testFile: TestFile) => {
          ListItem() {
            this.TestFileItem(testFile)
          }
        }, (testFile: TestFile) => testFile.fileName)
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .height('100%')
  }
  
  @Builder
  TestFileItem(testFile: TestFile) {
    Row() {
      // Icon
      Text(testFile.icon)
        .fontSize(32)
        .width(48)
        .height(48)
        .textAlign(TextAlign.Center)
        .backgroundColor('#F0F0F0')
        .borderRadius(8)
      
      // File info
      Column() {
        Text(testFile.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
        
        Text(testFile.fileName)
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 16 })
      .layoutWeight(1)
      
      // Type badge
      Text(testFile.type === FileType.HTML ? 'HTML' : 'MD')
        .fontSize(12)
        .fontColor('#FFFFFF')
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .borderRadius(4)
        .backgroundColor(testFile.type === FileType.HTML ? '#FF6B6B' : '#4ECDC4')
      
      // Arrow
      Text('›')
        .fontSize(24)
        .fontColor('#CCCCCC')
        .margin({ left: 8 })
    }
    .width('100%')
    .padding({ top: 12, bottom: 12, left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .margin({ bottom: 8 })
    .onClick(() => {
      this.openTestFile(testFile);
    })
  }
  
  /**
   * Open a test file
   */
  private async openTestFile(testFile: TestFile): Promise<void> {
    hilog.info(DOMAIN, TAG, 'Opening test file: %{public}s', testFile.fileName);
    this.isLoading = true;
    this.errorMessage = '';
    
    try {
      // Get resource manager
      const context = getContext(this) as common.UIAbilityContext;
      const resMgr = context.resourceManager;
      
      // Read file content from rawfile
      const content = await this.readRawFile(resMgr, testFile.fileName);
      hilog.info(DOMAIN, TAG, 'Test file content read, length: %{public}d', content.length);
      
      this.isLoading = false;
      
      // Navigate to appropriate viewer
      if (testFile.type === FileType.HTML) {
        hilog.info(DOMAIN, TAG, 'Navigating to HTML viewer');
        router.pushUrl({
          url: 'pages/HtmlViewer',
          params: {
            content: content,
            fileName: testFile.fileName
          }
        });
      } else if (testFile.type === FileType.MARKDOWN) {
        hilog.info(DOMAIN, TAG, 'Navigating to Markdown viewer');
        router.pushUrl({
          url: 'pages/MarkdownViewer',
          params: {
            content: content,
            fileName: testFile.fileName
          }
        });
      }
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to open test file: %{public}s', JSON.stringify(err));
      this.isLoading = false;
      this.errorMessage = `Failed to load test file: ${testFile.fileName}`;
    }
  }
  
  /**
   * Read rawfile content
   */
  private async readRawFile(resMgr: resourceManager.ResourceManager, fileName: string): Promise<string> {
    try {
      const fileData = await resMgr.getRawFileContent(fileName);
      const decoder = util.TextDecoder.create('utf-8');
      return decoder.decodeToString(new Uint8Array(fileData));
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to read rawfile: %{public}s', JSON.stringify(err));
      throw new Error(`Failed to read rawfile: ${JSON.stringify(err)}`);
    }
  }
}
