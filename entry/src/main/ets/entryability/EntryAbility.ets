import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { systemShare } from '@kit.ShareKit';
import { BusinessError } from '@kit.BasicServicesKit';

const DOMAIN = 0x0000;
const TAG = 'FileViewer';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onCreate');
    
    // Handle share data
    this.handleShareData(want);
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onNewWant');
    // Handle share data when app is already running
    this.handleShareData(want);
  }

  onDestroy(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, TAG, 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onBackground');
  }

  /**
   * Handle shared data from other apps
   */
  private handleShareData(want: Want): void {
    hilog.info(DOMAIN, TAG, 'handleShareData called with want: %{public}s', JSON.stringify(want));
    
    systemShare.getSharedData(want).then((data: systemShare.SharedData) => {
      hilog.info(DOMAIN, TAG, 'getSharedData success, record count: %{public}d', data.getRecords().length);
      
      const records = data.getRecords();
      if (records.length > 0) {
        const record = records[0];
        hilog.info(DOMAIN, TAG, 'Shared record - URI: %{public}s, UTD: %{public}s', 
          record.uri ?? 'null', record.utd ?? 'null');
        
        // Store shared data in AppStorage for UI to access
        AppStorage.setOrCreate('sharedFileUri', record.uri ?? '');
        AppStorage.setOrCreate('sharedFileUtd', record.utd ?? '');
        AppStorage.setOrCreate('hasSharedData', true);
      } else {
        hilog.warn(DOMAIN, TAG, 'No shared records found');
        AppStorage.setOrCreate('hasSharedData', false);
      }
    }).catch((err: BusinessError) => {
      hilog.error(DOMAIN, TAG, 'getSharedData failed: %{public}s', JSON.stringify(err));
      AppStorage.setOrCreate('hasSharedData', false);
    });
  }
}