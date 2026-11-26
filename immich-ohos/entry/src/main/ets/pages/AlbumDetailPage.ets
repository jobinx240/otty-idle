import { AlbumsViewModel } from '../viewmodel/AlbumsViewModel';
import { TimelineAssetCell } from '../viewmodel/TimelineViewModel';
import { AuthThumb } from '../components/AuthThumb';
import { NavUtil } from '../common/NavUtil';
import { AlbumRouteParams, AssetRouteParams } from '../common/NavParams';

@Entry
@Component
struct AlbumDetailPage {
  @State private title: string = '';
  @State private assets: TimelineAssetCell[] = [];
  @State private busy: boolean = false;
  @State private errorMessage: string = '';
  private albumId: string = '';
  private vm: AlbumsViewModel = new AlbumsViewModel();
  private cellSize: number = 118;

  aboutToAppear(): void {
    const params = NavUtil.params<AlbumRouteParams>(this.getUIContext());
    this.albumId = params?.albumId ?? '';
    this.title = params?.albumName ?? 'Album';
    this.reload();
  }

  private async reload(): Promise<void> {
    if (this.albumId.length === 0) {
      this.errorMessage = 'Missing album id';
      return;
    }
    this.busy = true;
    await this.vm.loadAlbumAssets(this.albumId, this.title);
    this.assets = this.vm.assets;
    this.title = this.vm.albumTitle;
    this.errorMessage = this.vm.errorMessage;
    this.busy = this.vm.busy;
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
        Text(this.title)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .margin({ left: 8 })
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .padding(12)

      if (this.busy) {
        LoadingProgress().width(48).height(48).margin({ top: 40 })
      } else if (this.errorMessage.length > 0) {
        Text(this.errorMessage).fontColor($r('app.color.danger')).padding(16)
      } else if (this.assets.length === 0) {
        Text('No assets in this album yet.').fontColor($r('app.color.text_secondary')).padding(24)
      } else {
        Grid() {
          ForEach(this.assets, (item: TimelineAssetCell) => {
            GridItem() {
              AuthThumb({ assetId: item.id, cellSize: this.cellSize })
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
