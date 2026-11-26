import { ServerApi } from '../service/ServerApi';
import { AuthApi } from '../service/AuthApi';
import { SessionStore } from '../service/SessionStore';
import { thumbnailLoader } from '../service/ThumbnailLoader';
import { HttpError, immichHttp } from '../service/HttpClient';
import { NavUtil } from '../common/NavUtil';

@Entry
@Component
struct SettingsPage {
  @State private serverUrl: string = '';
  @State private email: string = '';
  @State private userName: string = '';
  @State private versionText: string = '';
  @State private aboutText: string = '';
  @State private message: string = '';
  @State private busy: boolean = false;
  private serverApi: ServerApi = new ServerApi(immichHttp);
  private authApi: AuthApi = new AuthApi(immichHttp);

  aboutToAppear(): void {
    this.reload();
  }

  private async reload(): Promise<void> {
    this.busy = true;
    this.message = '';
    try {
      await immichHttp.loadFromSession();
      this.serverUrl = await SessionStore.getServerUrl();
      this.email = await SessionStore.getUserEmail();
      this.userName = await SessionStore.getUserName();
      try {
        const me = await this.authApi.getMe();
        this.email = me.email ?? this.email;
        this.userName = me.name ?? this.userName;
      } catch (_e) {
        // session fields are enough
      }
      try {
        const ver = await this.serverApi.version();
        this.versionText = `${ver.major ?? '?'}.${ver.minor ?? '?'}.${ver.patch ?? '?'}`;
      } catch (_e) {
        this.versionText = 'unknown';
      }
      try {
        const about = await this.serverApi.about();
        this.aboutText = about.version ?? about.build ?? '';
      } catch (_e) {
        this.aboutText = '';
      }
    } finally {
      this.busy = false;
    }
  }

  private onClearCache(): void {
    thumbnailLoader.clear();
    this.message = 'Thumbnail cache cleared';
  }

  private async onLogout(): Promise<void> {
    try {
      await this.authApi.logout();
    } catch (_e) {
      // clear local anyway
    }
    thumbnailLoader.clear();
    await SessionStore.clear();
    NavUtil.replace(this.getUIContext(), 'pages/LoginPage');
  }

  build() {
    Column({ space: 12 }) {
      Row() {
        Button('Back')
          .backgroundColor(Color.Transparent)
          .fontColor($r('app.color.brand'))
          .onClick(() => {
            NavUtil.back(this.getUIContext());
          })
        Text($r('app.string.settings_title'))
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .margin({ left: 8 })
          .layoutWeight(1)
      }
      .width('100%')
      .padding(12)

      if (this.busy) {
        LoadingProgress().width(40).height(40)
      }

      Text('Account')
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .padding({ left: 16, right: 16 })
      Text(`${this.userName} (${this.email})`)
        .fontSize(16)
        .fontColor($r('app.color.text_primary'))
        .width('100%')
        .padding({ left: 16, right: 16 })

      Text('Server')
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .padding({ left: 16, right: 16, top: 8 })
      Text(this.serverUrl)
        .fontSize(14)
        .fontColor($r('app.color.text_primary'))
        .width('100%')
        .padding({ left: 16, right: 16 })
      Text(`API version ${this.versionText}${this.aboutText.length > 0 ? ` · ${this.aboutText}` : ''}`)
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .padding({ left: 16, right: 16 })

      if (this.message.length > 0) {
        Text(this.message)
          .fontSize(13)
          .fontColor($r('app.color.brand'))
          .padding({ left: 16, right: 16 })
      }

      Button('Clear thumbnail cache')
        .width('90%')
        .margin({ top: 16 })
        .backgroundColor($r('app.color.brand'))
        .onClick(() => {
          this.onClearCache();
        })

      Button($r('app.string.logout'))
        .width('90%')
        .margin({ top: 8 })
        .backgroundColor($r('app.color.danger'))
        .onClick(() => {
          this.onLogout();
        })
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .backgroundColor($r('app.color.page_background'))
  }
}
