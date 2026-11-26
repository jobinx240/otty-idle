import { TimelineAssetCell, TimelineViewModel } from '../viewmodel/TimelineViewModel';
import { AuthThumb } from '../components/AuthThumb';
import { thumbnailLoader } from '../service/ThumbnailLoader';
import { NavUtil } from '../common/NavUtil';
import { AssetRouteParams } from '../common/NavParams';

@Entry
@Component
struct TimelinePage {
  @State private userName: string = '';
  @State private assets: TimelineAssetCell[] = [];
  @State private busy: boolean = false;
  @State private errorMessage: string = '';
  private vm: TimelineViewModel = new TimelineViewModel();
  private cellSize: number = 118;

  aboutToAppear(): void {
    this.reload();
  }

  private async reload(): Promise<void> {
    this.busy = true;
    await this.vm.load();
    this.userName = this.vm.userName;
    this.assets = this.vm.assets;
    this.errorMessage = this.vm.errorMessage;
    this.busy = this.vm.busy;
  }

  private async onLogout(): Promise<void> {
    thumbnailLoader.clear();
    await this.vm.logout();
    NavUtil.replace(this.getUIContext(), 'pages/LoginPage');
  }

  build() {
    Column() {
      Column({ space: 4 }) {
        Text($r('app.string.timeline_title'))
          .fontSize(22)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
          .width('100%')
        if (this.userName.length > 0) {
          Text(this.userName)
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
            .maxLines(1)
            .width('100%')
        }
        Flex({ wrap: FlexWrap.Wrap }) {
          Button($r('app.string.albums_title'))
            .fontSize(13)
            .height(36)
            .backgroundColor(Color.Transparent)
            .fontColor($r('app.color.brand'))
            .onClick(() => {
              NavUtil.push(this.getUIContext(), 'pages/AlbumsPage');
            })
          Button($r('app.string.search_title'))
            .fontSize(13)
            .height(36)
            .backgroundColor(Color.Transparent)
            .fontColor($r('app.color.brand'))
            .onClick(() => {
              NavUtil.push(this.getUIContext(), 'pages/SearchPage');
            })
          Button($r('app.string.backup_title'))
            .fontSize(13)
            .height(36)
            .backgroundColor(Color.Transparent)
            .fontColor($r('app.color.brand'))
            .onClick(() => {
              NavUtil.push(this.getUIContext(), 'pages/BackupPage');
            })
          Button($r('app.string.people_title'))
            .fontSize(13)
            .height(36)
            .backgroundColor(Color.Transparent)
            .fontColor($r('app.color.brand'))
            .onClick(() => {
              NavUtil.push(this.getUIContext(), 'pages/PeoplePage');
            })
          Button($r('app.string.settings_title'))
            .fontSize(13)
            .height(36)
            .backgroundColor(Color.Transparent)
            .fontColor($r('app.color.brand'))
            .onClick(() => {
              NavUtil.push(this.getUIContext(), 'pages/SettingsPage');
            })
          Button($r('app.string.logout'))
            .fontSize(13)
            .height(36)
            .backgroundColor(Color.Transparent)
            .fontColor($r('app.color.brand'))
            .onClick(() => {
              this.onLogout();
            })
        }
        .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 12, right: 12, top: 12, bottom: 8 })

      if (this.busy) {
        LoadingProgress()
          .width(48)
          .height(48)
          .margin({ top: 40 })
      } else if (this.errorMessage.length > 0) {
        Text(this.errorMessage)
          .fontColor($r('app.color.danger'))
          .padding(16)
          .width('100%')
        Button('Retry')
          .onClick(() => {
            this.reload();
          })
      } else if (this.assets.length === 0) {
        Text('No assets in the first timeline buckets yet.')
          .fontColor($r('app.color.text_secondary'))
          .padding(24)
        Button($r('app.string.backup_title'))
          .margin({ top: 8 })
          .backgroundColor($r('app.color.brand'))
          .onClick(() => {
            NavUtil.push(this.getUIContext(), 'pages/BackupPage');
          })
      } else {
        Grid() {
          ForEach(this.assets, (item: TimelineAssetCell) => {
            GridItem() {
              AuthThumb({
                assetId: item.id,
                cellSize: this.cellSize,
                isVideo: !item.isImage,
                isFavorite: item.isFavorite
              })
                .onClick(() => {
                  NavUtil.push(this.getUIContext(), 'pages/AssetViewerPage', new AssetRouteParams(item.id));
                })
            }
          }, (item: TimelineAssetCell) => item.id)
        }
        .columnsTemplate('1fr 1fr 1fr')
        .columnsGap(4)
        .rowsGap(4)
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
