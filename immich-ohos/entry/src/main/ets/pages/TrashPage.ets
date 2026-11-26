import { FilteredLibraryViewModel } from '../viewmodel/FilteredLibraryViewModel';
import { TimelineAssetCell } from '../viewmodel/TimelineViewModel';
import { AuthThumb } from '../components/AuthThumb';
import { NavUtil } from '../common/NavUtil';
import { AssetRouteParams } from '../common/NavParams';

@Entry
@Component
struct TrashPage {
  @State private assets: TimelineAssetCell[] = [];
  @State private busy: boolean = false;
  @State private errorMessage: string = '';
  @State private actionMessage: string = '';
  private vm: FilteredLibraryViewModel = new FilteredLibraryViewModel();
  private cellSize: number = 118;

  aboutToAppear(): void {
    this.reload();
  }

  private async reload(): Promise<void> {
    this.busy = true;
    await this.vm.loadTrash();
    this.assets = this.vm.assets;
    this.errorMessage = this.vm.errorMessage;
    this.actionMessage = this.vm.actionMessage;
    this.busy = this.vm.busy;
  }

  private async onRestoreAll(): Promise<void> {
    await this.vm.restoreAll();
    this.assets = this.vm.assets;
    this.actionMessage = this.vm.actionMessage;
  }

  private async onEmpty(): Promise<void> {
    await this.vm.emptyTrash();
    this.assets = this.vm.assets;
    this.actionMessage = this.vm.actionMessage;
  }

  private async onRestoreOne(id: string): Promise<void> {
    await this.vm.restoreAsset(id);
    this.assets = this.vm.assets;
    this.actionMessage = this.vm.actionMessage;
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
        Text($r('app.string.trash_title'))
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .margin({ left: 8 })
          .layoutWeight(1)
        Button('Restore all')
          .fontSize(12)
          .backgroundColor(Color.Transparent)
          .fontColor($r('app.color.brand'))
          .enabled(!this.busy && this.assets.length > 0)
          .onClick(() => {
            this.onRestoreAll();
          })
        Button('Empty')
          .fontSize(12)
          .backgroundColor(Color.Transparent)
          .fontColor($r('app.color.danger'))
          .enabled(!this.busy && this.assets.length > 0)
          .onClick(() => {
            this.onEmpty();
          })
      }
      .width('100%')
      .padding(12)

      if (this.actionMessage.length > 0) {
        Text(this.actionMessage)
          .fontSize(12)
          .fontColor('#FFD54F')
          .padding({ left: 12, right: 12, bottom: 8 })
          .width('100%')
      }

      if (this.busy) {
        LoadingProgress().width(48).height(48).margin({ top: 40 })
      } else if (this.errorMessage.length > 0) {
        Text(this.errorMessage).fontColor($r('app.color.danger')).padding(16)
        Button('Retry').onClick(() => {
          this.reload();
        })
      } else if (this.assets.length === 0) {
        Text('Trash is empty')
          .fontColor($r('app.color.text_secondary'))
          .padding(24)
      } else {
        Grid() {
          ForEach(this.assets, (item: TimelineAssetCell) => {
            GridItem() {
              Column({ space: 4 }) {
                AuthThumb({
                  assetId: item.id,
                  cellSize: this.cellSize,
                  isVideo: !item.isImage,
                  isFavorite: item.isFavorite
                })
                  .onClick(() => {
                    NavUtil.push(this.getUIContext(), 'pages/AssetViewerPage', new AssetRouteParams(item.id));
                  })
                Button('Restore')
                  .fontSize(11)
                  .height(28)
                  .width('100%')
                  .backgroundColor($r('app.color.brand'))
                  .onClick(() => {
                    this.onRestoreOne(item.id);
                  })
              }
            }
          }, (item: TimelineAssetCell) => item.id)
        }
        .columnsTemplate('1fr 1fr 1fr')
        .columnsGap(4)
        .rowsGap(8)
        .padding(8)
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
  }
}
