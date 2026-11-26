import { LoginViewModel } from '../viewmodel/LoginViewModel';
import { NavUtil } from '../common/NavUtil';
import { Constants } from '../common/Constants';

@Entry
@Component
struct LoginPage {
  @State private serverUrl: string = '';
  @State private email: string = '';
  @State private password: string = '';
  @State private useCustomCa: boolean = false;
  @State private customCaPem: string = '';
  @State private busy: boolean = false;
  @State private errorMessage: string = '';
  @State private warningMessage: string = '';
  private vm: LoginViewModel = new LoginViewModel();

  aboutToAppear(): void {
    this.vm.loadSavedServer().then(() => {
      this.serverUrl = this.vm.serverUrl;
      this.email = this.vm.email;
      this.useCustomCa = this.vm.useCustomCa;
      this.customCaPem = this.vm.customCaPem;
    });
  }

  private applyDebugPrefill(): void {
    this.serverUrl = Constants.DEBUG_SERVER_URL;
    this.email = Constants.DEBUG_EMAIL;
    this.password = Constants.DEBUG_PASSWORD;
    this.errorMessage = '';
    this.warningMessage = '';
  }

  private async onLogin(): Promise<void> {
    this.vm.serverUrl = this.serverUrl;
    this.vm.email = this.email;
    this.vm.password = this.password;
    this.vm.useCustomCa = this.useCustomCa;
    this.vm.customCaPem = this.customCaPem;
    this.busy = true;
    this.errorMessage = '';
    this.warningMessage = '';
    const ok = await this.vm.login();
    this.busy = this.vm.busy;
    this.errorMessage = this.vm.errorMessage;
    this.warningMessage = this.vm.warningMessage;
    this.password = this.vm.password;
    if (ok) {
      NavUtil.replace(this.getUIContext(), 'pages/TimelinePage');
    }
  }

  build() {
    Column({ space: 12 }) {
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

      Row() {
        Text($r('app.string.custom_ca_toggle'))
          .fontSize(14)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.useCustomCa })
          .onChange((on: boolean) => {
            this.useCustomCa = on;
          })
      }
      .width('100%')

      if (this.useCustomCa) {
        Text($r('app.string.custom_ca_pem'))
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
        TextArea({ placeholder: '-----BEGIN CERTIFICATE-----', text: this.customCaPem })
          .width('100%')
          .height(100)
          .onChange((v: string) => {
            this.customCaPem = v;
          })
      }

      if (this.warningMessage.length > 0) {
        Text(this.warningMessage)
          .fontSize(13)
          .fontColor('#E6A23C')
          .width('100%')
      }
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
