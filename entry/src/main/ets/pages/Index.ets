import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { FileUtils, FileType } from '../utils/FileUtils';
import { resourceManager } from '@kit.LocalizationKit';
import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';

const DOMAIN = 0x0000;
const TAG = 'IndexPage';

// Sample file definition
interface SampleFile {
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
  @State showSampleFiles: boolean = false;
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
  
  // Sample files list
  private sampleFiles: SampleFile[] = [
    { name: '基础 HTML', fileName: 'simple.html', type: FileType.HTML, icon: '🌐' },
    { name: '复杂 HTML', fileName: 'rich.html', type: FileType.HTML, icon: '🎨' },
    { name: '中文 HTML', fileName: 'chinese.html', type: FileType.HTML, icon: '🇨🇳' },
    { name: 'HTML 动画演示', fileName: 'html-ppt.html', type: FileType.HTML, icon: '🎬' },
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
      } else if (this.showSampleFiles) {
        this.SampleFilesView();
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

  // ==================== WelcomeView (Redesigned) ====================

  @Builder
  WelcomeView() {
    Scroll() {
      Column() {
        // ---- Hero Section ----
        Column() {
          // App icon — styled circular badge with initials
          Stack() {
            Circle()
              .width(88)
              .height(88)
              .fill('#E8F0FE')
            Text('FV')
              .fontSize(36)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1A73E8')
          }
          .width(88)
          .height(88)

          // App title
          Text('File Viewer')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1A1A1A')
            .margin({ top: 20 })

          // Tagline
          Text('轻量级 HTML 与 Markdown 文件预览工具')
            .fontSize(15)
            .fontColor('#666666')
            .margin({ top: 8 })
            .textAlign(TextAlign.Center)
            .padding({ left: 40, right: 40 })

          // Supported format badges
          Row() {
            this.FormatBadge('HTML', '#FF6B6B', '#FFF0F0')
            this.FormatBadge('Markdown', '#4ECDC4', '#E8FAF8')
          }
          .margin({ top: 16 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .padding({ top: 48, bottom: 24 })

        // ---- Divider ----
        Divider()
          .width('80%')
          .color('#E0E0E0')
          .margin({ top: 8, bottom: 8 })

        // ---- Usage Guide Section ----
        Column() {
          Text('使用方式')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
            .margin({ bottom: 16 })

          this.GuideStep('1', '从其他应用（如文件管理器）打开文件')
          this.GuideStep('2', '选择「分享」或「打开方式」')
          this.GuideStep('3', '选择 File Viewer 完成预览')
        }
        .width('100%')
        .padding({ left: 32, right: 32, top: 16, bottom: 16 })
        .alignItems(HorizontalAlign.Start)

        // ---- Divider ----
        Divider()
          .width('80%')
          .color('#E0E0E0')
          .margin({ top: 8, bottom: 8 })

        // ---- Sample Files Button ----
        Button('浏览内置示例文件')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor('#1A73E8')
          .borderRadius(24)
          .height(48)
          .width(220)
          .margin({ top: 24 })
          .shadow({ radius: 8, color: '#331A73E8', offsetX: 0, offsetY: 4 })
          .onClick(() => {
            this.showSampleFiles = true;
          })

        // ---- Spacer ----
        Blank()
          .height(24)

        // ---- Footer / Author Section ----
        Column() {
          Divider()
            .width('80%')
            .color('#E0E0E0')
            .margin({ bottom: 20 })

          Text('关于')
            .fontSize(13)
            .fontColor('#999999')
            .margin({ bottom: 6 })

          Text('File Viewer — 开源 HarmonyOS 文件预览应用')
            .fontSize(12)
            .fontColor('#AAAAAA')
            .textAlign(TextAlign.Center)

          Text('基于 marked.js Markdown 解析引擎')
            .fontSize(12)
            .fontColor('#AAAAAA')
            .margin({ top: 4 })
            .textAlign(TextAlign.Center)

          Text('GitHub: github.com/agirayaksoy/harmony-html-md-preview')
            .fontSize(12)
            .fontColor('#1A73E8')
            .margin({ top: 8 })
            .textAlign(TextAlign.Center)
            .decoration({ type: TextDecorationType.Underline, color: '#1A73E8' })

          Text('作者: Agiray Aksoy')
            .fontSize(12)
            .fontColor('#BBBBBB')
            .margin({ top: 8, bottom: 16 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }

  @Builder
  GuideStep(number: string, text: string) {
    Row() {
      Text(number)
        .fontSize(13)
        .fontColor('#FFFFFF')
        .fontWeight(FontWeight.Medium)
        .width(24)
        .height(24)
        .textAlign(TextAlign.Center)
        .borderRadius(12)
        .backgroundColor('#1A73E8')
      
      Text(text)
        .fontSize(14)
        .fontColor('#555555')
        .margin({ left: 12 })
        .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .margin({ bottom: 12 })
  }

  @Builder
  FormatBadge(format: string, textColor: string, bgColor: string) {
    Text(format)
      .fontSize(12)
      .fontColor(textColor)
      .fontWeight(FontWeight.Medium)
      .padding({ left: 14, right: 14, top: 6, bottom: 6 })
      .borderRadius(16)
      .backgroundColor(bgColor)
      .margin({ left: 6, right: 6 })
  }
  
  // ==================== Sample Files View ====================

  @Builder
  SampleFilesView() {
    Column() {
      // Header
      Row() {
        Button('← 返回')
          .fontSize(16)
          .fontColor('#1A73E8')
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.showSampleFiles = false;
          })
        
        Blank()
        
        Text('示例文件')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')
        
        Blank()
        
        Button('← 返回')
          .fontSize(16)
          .fontColor('#1A73E8')
          .backgroundColor(Color.Transparent)
          .visibility(Visibility.Hidden)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })
      
      // Description
      Text('选择一个示例文件来预览渲染效果')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ top: 8, bottom: 16 })
      
      // Sample files list
      List() {
        ForEach(this.sampleFiles, (sampleFile: SampleFile) => {
          ListItem() {
            this.SampleFileItem(sampleFile)
          }
        }, (sampleFile: SampleFile) => sampleFile.fileName)
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .height('100%')
  }
  
  @Builder
  SampleFileItem(sampleFile: SampleFile) {
    Row() {
      // Icon
      Text(sampleFile.icon)
        .fontSize(28)
        .width(48)
        .height(48)
        .textAlign(TextAlign.Center)
        .backgroundColor('#F0F4F8')
        .borderRadius(12)
      
      // File info
      Column() {
        Text(sampleFile.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
        
        Text(sampleFile.fileName)
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 16 })
      .layoutWeight(1)
      
      // Type badge
      Text(sampleFile.type === FileType.HTML ? 'HTML' : 'MD')
        .fontSize(11)
        .fontColor('#FFFFFF')
        .fontWeight(FontWeight.Medium)
        .padding({ left: 10, right: 10, top: 4, bottom: 4 })
        .borderRadius(12)
        .backgroundColor(sampleFile.type === FileType.HTML ? '#FF6B6B' : '#4ECDC4')
      
      // Arrow
      Text('›')
        .fontSize(24)
        .fontColor('#CCCCCC')
        .margin({ left: 8 })
    }
    .width('100%')
    .padding({ top: 14, bottom: 14, left: 16, right: 16 })
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 8 })
    .shadow({ radius: 2, color: '#0D000000', offsetX: 0, offsetY: 1 })
    .onClick(() => {
      this.openSampleFile(sampleFile);
    })
  }
  
  /**
   * Open a sample file
   */
  private async openSampleFile(sampleFile: SampleFile): Promise<void> {
    hilog.info(DOMAIN, TAG, 'Opening sample file: %{public}s', sampleFile.fileName);
    this.isLoading = true;
    this.errorMessage = '';
    
    try {
      // Get resource manager
      const context = getContext(this) as common.UIAbilityContext;
      const resMgr = context.resourceManager;
      
      // Read file content from rawfile
      const content = await this.readRawFile(resMgr, sampleFile.fileName);
      hilog.info(DOMAIN, TAG, 'Sample file content read, length: %{public}d', content.length);
      
      this.isLoading = false;
      
      // Navigate to appropriate viewer
      if (sampleFile.type === FileType.HTML) {
        hilog.info(DOMAIN, TAG, 'Navigating to HTML viewer');
        router.pushUrl({
          url: 'pages/HtmlViewer',
          params: {
            content: content,
            fileName: sampleFile.fileName
          }
        });
      } else if (sampleFile.type === FileType.MARKDOWN) {
        hilog.info(DOMAIN, TAG, 'Navigating to Markdown viewer');
        router.pushUrl({
          url: 'pages/MarkdownViewer',
          params: {
            content: content,
            fileName: sampleFile.fileName
          }
        });
      }
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to open sample file: %{public}s', JSON.stringify(err));
      this.isLoading = false;
      this.errorMessage = `Failed to load sample file: ${sampleFile.fileName}`;
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
