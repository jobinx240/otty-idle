import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { SessionStore } from '../service/SessionStore';
import { immichHttp } from '../service/HttpClient';
import { AuthApi } from '../service/AuthApi';

const DOMAIN = 0x3200;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (_e) {
      // Older SDKs may not expose setColorMode the same way.
    }
    hilog.info(DOMAIN, 'ImmichOH', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'ImmichOH', 'Ability onDestroy');
  }

  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    hilog.info(DOMAIN, 'ImmichOH', 'Ability onWindowStageCreate');
    await SessionStore.init(this.context);
    await immichHttp.loadFromSession();

    let startPage = 'pages/LoginPage';
    if (await SessionStore.hasSession()) {
      try {
        const auth = new AuthApi(immichHttp);
        const status = await auth.validateToken();
        if (status.authStatus) {
          startPage = 'pages/TimelinePage';
        } else {
          await SessionStore.clear();
        }
      } catch (_e) {
        // Keep LoginPage when offline / invalid token.
        startPage = 'pages/LoginPage';
      }
    }

    windowStage.loadContent(startPage, (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'ImmichOH', 'loadContent failed: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'ImmichOH', 'loadContent %{public}s', startPage);
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'ImmichOH', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'ImmichOH', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'ImmichOH', 'Ability onBackground');
  }
}
