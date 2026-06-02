import { webview } from '@kit.ArkWeb';
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { util } from '@kit.ArkTS';

const DOMAIN = 0x0000;
const TAG = 'HtmlViewer';

@Entry
@Component
struct HtmlViewerPage {
  @State htmlContent: string = '';
  @State fileName: string = '';
  @State isLoading: boolean = true;
  @State errorMessage: string = '';
  @State dataUrl: string = '';
  
  private webController: webview.WebviewController = new webview.WebviewController();

  aboutToAppear(): void {
    hilog.info(DOMAIN, TAG, 'HtmlViewerPage aboutToAppear');
    
    // Get parameters from router
    const params = router.getParams() as Record<string, string>;
    if (params) {
      this.htmlContent = params['content'] ?? '';
      this.fileName = params['fileName'] ?? 'Untitled.html';
      hilog.info(DOMAIN, TAG, 'Received content length: %{public}d', this.htmlContent.length);
      hilog.info(DOMAIN, TAG, 'Received fileName: %{public}s', this.fileName);
      
      if (this.htmlContent.length === 0) {
        this.errorMessage = 'No HTML content received';
        this.isLoading = false;
      } else {
        // Create data URL for Web component
        try {
          // Encode HTML content for data URL
          const encoder = util.TextEncoder.create('utf-8');
          const encodedBytes = encoder.encodeInto(this.htmlContent);
          
          // Convert to base64
          const base64Helper = new util.Base64Helper();
          const encodedStr = base64Helper.encodeToStringSync(encodedBytes);
          
          // Create data URL
          this.dataUrl = `data:text/html;base64,${encodedStr}`;
          
          hilog.info(DOMAIN, TAG, 'Data URL created, length: %{public}d', this.dataUrl.length);
          this.isLoading = false;
        } catch (err) {
          hilog.error(DOMAIN, TAG, 'Failed to create data URL: %{public}s', JSON.stringify(err));
          this.errorMessage = 'Failed to process HTML content';
          this.isLoading = false;
        }
      }
    } else {
      hilog.error(DOMAIN, TAG, 'No parameters received from router');
      this.errorMessage = 'Failed to load content';
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      // Title bar
      this.TitleBar();
      
      // Content area
      if (this.errorMessage.length > 0) {
        this.ErrorView();
      } else if (this.isLoading) {
        this.LoadingView();
      } else {
        this.HtmlContentView();
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
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
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
  HtmlContentView() {
    Column() {
      if (this.dataUrl.length > 0) {
        Web({ src: this.dataUrl, controller: this.webController })
          .width('100%')
          .layoutWeight(1)
          .backgroundColor('#FFFFFF')
          .javaScriptAccess(true)
          .domStorageAccess(true)
          .onPageEnd(() => {
            hilog.info(DOMAIN, TAG, 'Web page loaded successfully');
          })
          .onErrorReceive((event) => {
            hilog.error(DOMAIN, TAG, 'Web error: %{public}s', JSON.stringify(event));
            if (event && event.error) {
              this.errorMessage = `Failed to render HTML: ${event.error.getErrorInfo()}`;
            } else {
              this.errorMessage = 'Failed to render HTML content';
            }
          })
      } else {
        // Fallback: show error if data URL not created
        Column() {
          Text('Failed to load content')
            .fontSize(16)
            .fontColor('#999999')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
    .layoutWeight(1)
  }
}
