import { BackupViewModel } from '../viewmodel/BackupViewModel';
import { LocalUploadItem } from '../model/AssetModels';
import { NavUtil } from '../common/NavUtil';

@Entry
@Component
struct BackupPage {
  @State private items: LocalUploadItem[] = [];
  @State private busy: boolean = false;
  @State private errorMessage: string = '';
  @State private doneCount: number = 0;
  private vm: BackupViewModel = new BackupViewModel();

  private syncFromVm(): void {
    this.items = this.vm.items.slice();
    this.busy = this.vm.busy;
    this.errorMessage = this.vm.errorMessage;
    this.doneCount = this.vm.doneCount;
  }

  private async onPick(): Promise<void> {
    await this.vm.pickImages();
    this.syncFromVm();
  }

  private async onUpload(): Promise<void> {
    this.busy = true;
    await this.vm.uploadAll(() => {
      this.syncFromVm();
    });
    this.syncFromVm();
  }

  build() {
    Column() {
      Row() {
        Button('Back')
          .backgroundColor(Color.Transparent)
          .fontColor($r('app.color.brand'))
          .onClick(() => {
            NavUtil.back(this.getUIContext());
          })
        Text($r('app.string.backup_title'))
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .margin({ left: 8 })
          .layoutWeight(1)
      }
      .width('100%')
      .padding(12)

      Row({ space: 12 }) {
        Button($r('app.string.pick_photos'))
          .layoutWeight(1)
          .height(44)
          .backgroundColor($r('app.color.brand'))
          .enabled(!this.busy)
          .onClick(() => {
            this.onPick();
          })
        Button($r('app.string.upload'))
          .layoutWeight(1)
          .height(44)
          .backgroundColor($r('app.color.brand'))
          .enabled(!this.busy && this.items.length > 0)
          .onClick(() => {
            this.onUpload();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 8 })

      if (this.items.length > 0) {
        Text(`Selected ${this.items.length} · Done ${this.doneCount}`)
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 8 })
      }

      if (this.errorMessage.length > 0) {
        Text(this.errorMessage)
          .fontColor($r('app.color.danger'))
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 8 })
      }

      List() {
        ForEach(this.items, (item: LocalUploadItem) => {
          ListItem() {
            Column({ space: 4 }) {
              Text(item.fileName)
                .fontSize(14)
                .fontColor($r('app.color.text_primary'))
                .width('100%')
              Text(`${item.status}${item.message.length > 0 ? ` — ${item.message}` : ''}`)
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
                .width('100%')
            }
            .padding(12)
            .width('100%')
            .alignItems(HorizontalAlign.Start)
          }
        }, (item: LocalUploadItem) => `${item.deviceAssetId}:${item.status}:${item.message}`)
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
  }
}
