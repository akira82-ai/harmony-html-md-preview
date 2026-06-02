import { webview } from '@kit.ArkWeb';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;
const TAG = 'MarkdownViewer';

@Entry
@Component
struct MarkdownViewerPage {
  @State markdownContent: string = '';
  @State fileName: string = '';
  @State isLoading: boolean = true;
  @State errorMessage: string = '';
  
  private webController: webview.WebviewController = new webview.WebviewController();

  aboutToAppear(): void {
    hilog.info(DOMAIN, TAG, 'MarkdownViewerPage aboutToAppear');
    
    // Get parameters from router
    const params = router.getParams() as Record<string, string>;
    if (params) {
      this.markdownContent = params['content'] ?? '';
      this.fileName = params['fileName'] ?? 'Untitled.md';
      hilog.info(DOMAIN, TAG, 'Received content length: %{public}d', this.markdownContent.length);
      hilog.info(DOMAIN, TAG, 'Received fileName: %{public}s', this.fileName);
      
      if (this.markdownContent.length === 0) {
        hilog.error(DOMAIN, TAG, 'No Markdown content received');
        this.errorMessage = 'No Markdown content received';
        this.isLoading = false;
      } else {
        hilog.info(DOMAIN, TAG, 'Markdown content received, ready to render');
        // Don't set isLoading to false here, wait for web to load
      }
    } else {
      hilog.error(DOMAIN, TAG, 'No parameters received from router');
      this.errorMessage = 'Failed to load content';
      this.isLoading = false;
    }
    
    // Add timeout protection
    setTimeout(() => {
      if (this.isLoading) {
        hilog.error(DOMAIN, TAG, 'Markdown rendering timeout');
        this.errorMessage = 'Rendering timeout. Please try again.';
        this.isLoading = false;
      }
    }, 10000); // 10 seconds timeout
  }

  build() {
    Column() {
      // Title bar
      this.TitleBar();
      
      // Content area
      if (this.errorMessage.length > 0) {
        this.ErrorView();
      } else {
        // Always render Web component (it needs to load)
        Stack({ alignContent: Alignment.Center }) {
          // Web component (always present to trigger loading)
          this.MarkdownContentView();
          
          // Loading overlay
          if (this.isLoading) {
            this.LoadingView();
          }
        }
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  TitleBar() {
    Row() {
      // Back button
      Image($r('sys.media.ohos_ic_public_arrow_left'))
        .width(24)
        .height(24)
        .margin({ left: 16, right: 16 })
        .onClick(() => {
          router.back();
        })
      
      // File name
      Text(this.fileName)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#000000')
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      
      Blank()
        .width(16)
    }
    .width('100%')
    .height(56)
    .backgroundColor('#FFFFFF')
    .shadow({
      radius: 2,
      color: '#1F000000',
      offsetY: 2
    })
  }

  @Builder
  LoadingView() {
    Column() {
      LoadingProgress()
        .width(48)
        .height(48)
        .color('#007DFF')
      
      Text('Loading...')
        .fontSize(14)
        .fontColor('#999999')
        .margin({ top: 16 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('rgba(245, 245, 245, 0.9)') // Semi-transparent background
  }

  @Builder
  ErrorView() {
    Column() {
      Image($r('sys.media.ohos_ic_public_fail'))
        .width(48)
        .height(48)
        .fillColor('#FF0000')
      
      Text(this.errorMessage)
        .fontSize(14)
        .fontColor('#999999')
        .margin({ top: 16 })
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding({ left: 32, right: 32 })
  }

  @Builder
  MarkdownContentView() {
    Column() {
      Web({ src: $rawfile('markdown.html'), controller: this.webController })
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('#FFFFFF')
        .javaScriptAccess(true)
        .domStorageAccess(true)
        .fileAccess(true)
        .onPageBegin((event) => {
          hilog.info(DOMAIN, TAG, 'Web page begin loading: %{public}s', event?.url ?? 'unknown');
        })
        .onPageEnd((event) => {
          hilog.info(DOMAIN, TAG, 'Web page loaded successfully: %{public}s', event?.url ?? 'unknown');
          // Inject markdown content and render
          this.injectMarkdownContent();
        })
        .onErrorReceive((event) => {
          hilog.error(DOMAIN, TAG, 'Web error receive: %{public}s', JSON.stringify(event));
          this.errorMessage = 'Failed to load Markdown viewer';
          this.isLoading = false;
        })
        .onHttpErrorReceive((event) => {
          hilog.error(DOMAIN, TAG, 'Web HTTP error: %{public}s', JSON.stringify(event));
        })
    }
    .width('100%')
    .layoutWeight(1)
  }
  
  private injectMarkdownContent() {
    hilog.info(DOMAIN, TAG, 'Starting to inject markdown content');
    
    // Escape the markdown content for JavaScript
    const escapedContent = this.markdownContent
      .replace(/\\/g, '\\\\')
      .replace(/'/g, "\\'")
      .replace(/\n/g, '\\n')
      .replace(/\r/g, '\\r');
    
    const jsCode = `
      try {
        if (typeof renderMarkdown === 'function') {
          renderMarkdown('${escapedContent}');
          'success';
        } else {
          'renderMarkdown function not found';
        }
      } catch (e) {
        'Error: ' + e.message;
      }
    `;
    
    hilog.info(DOMAIN, TAG, 'JavaScript code length: %{public}d', jsCode.length);
    
    this.webController.runJavaScript(jsCode)
      .then((result) => {
        hilog.info(DOMAIN, TAG, 'JavaScript execution result: %{public}s', result ?? 'undefined');
        // Check if result contains 'success' (may have quotes)
        if (result && result.includes('success')) {
          hilog.info(DOMAIN, TAG, 'Markdown content injected successfully');
          this.isLoading = false;
        } else {
          hilog.error(DOMAIN, TAG, 'Markdown rendering failed: %{public}s', result ?? 'unknown');
          this.errorMessage = result ?? 'Failed to render Markdown';
          this.isLoading = false;
        }
      })
      .catch((err: Error) => {
        hilog.error(DOMAIN, TAG, 'Failed to inject markdown: %{public}s', err.message);
        this.errorMessage = 'Failed to render Markdown content';
        this.isLoading = false;
      });
  }
}
