import { LoginViewModel } from '../viewmodel/LoginViewModel';
import { NavUtil } from '../common/NavUtil';
import { Constants } from '../common/Constants';

@Entry
@Component
struct LoginPage {
  @State private serverUrl: string = '';
  @State private email: string = '';
  @State private password: string = '';
  @State private busy: boolean = false;
  @State private errorMessage: string = '';
  private vm: LoginViewModel = new LoginViewModel();

  aboutToAppear(): void {
    this.vm.loadSavedServer().then(() => {
      this.serverUrl = this.vm.serverUrl;
      this.email = this.vm.email;
    });
  }

  private applyDebugPrefill(): void {
    this.serverUrl = Constants.DEBUG_SERVER_URL;
    this.email = Constants.DEBUG_EMAIL;
    this.password = Constants.DEBUG_PASSWORD;
    this.errorMessage = '';
  }

  private async onLogin(): Promise<void> {
    this.vm.serverUrl = this.serverUrl;
    this.vm.email = this.email;
    this.vm.password = this.password;
    this.busy = true;
    this.errorMessage = '';
    const ok = await this.vm.login();
    this.busy = this.vm.busy;
    this.errorMessage = this.vm.errorMessage;
    this.password = this.vm.password;
    if (ok) {
      NavUtil.replace(this.getUIContext(), 'pages/TimelinePage');
    }
  }

  build() {
    Column({ space: 16 }) {
      Text($r('app.string.login_title'))
        .fontSize(28)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .margin({ bottom: 8 })
        .gesture(
          LongPressGesture({ repeat: false })
            .onAction(() => {
              this.applyDebugPrefill();
            })
        )

      Text($r('app.string.server_url'))
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
      TextInput({ placeholder: 'https://immich.example.com', text: this.serverUrl })
        .width('100%')
        .height(48)
        .onChange((v: string) => {
          this.serverUrl = v;
        })

      Text($r('app.string.email'))
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
      TextInput({ placeholder: 'you@example.com', text: this.email })
        .width('100%')
        .height(48)
        .onChange((v: string) => {
          this.email = v;
        })

      Text($r('app.string.password'))
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
      TextInput({ placeholder: '••••••••', text: this.password })
        .width('100%')
        .height(48)
        .type(InputType.Password)
        .onChange((v: string) => {
          this.password = v;
        })

      if (this.errorMessage.length > 0) {
        Text(this.errorMessage)
          .fontSize(13)
          .fontColor($r('app.color.danger'))
          .width('100%')
      }

      Button($r('app.string.login'))
        .width('100%')
        .height(48)
        .backgroundColor($r('app.color.brand'))
        .enabled(!this.busy)
        .onClick(() => {
          this.onLogin();
        })
    }
    .padding(24)
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('app.color.page_background'))
  }
}
