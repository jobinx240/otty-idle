import { image } from '@kit.ImageKit';
import { thumbnailLoader } from '../service/ThumbnailLoader';
import { NavUtil } from '../common/NavUtil';
import { AssetRouteParams } from '../common/NavParams';

@Entry
@Component
struct AssetViewerPage {
  @State private assetId: string = '';
  @State private pixelMap: image.PixelMap | undefined = undefined;
  @State private errorMessage: string = '';
  @State private busy: boolean = true;

  aboutToAppear(): void {
    const params = NavUtil.params<AssetRouteParams>(this.getUIContext());
    this.assetId = params?.assetId ?? '';
    this.loadPreview();
  }

  private async loadPreview(): Promise<void> {
    if (this.assetId.length === 0) {
      this.errorMessage = 'Missing asset id';
      this.busy = false;
      return;
    }
    this.busy = true;
    const pm = await thumbnailLoader.load(this.assetId, 'preview');
    if (pm) {
      this.pixelMap = pm;
    } else {
      this.errorMessage = 'Failed to load preview';
    }
    this.busy = false;
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
        Blank()
        Text(this.assetId)
          .fontSize(11)
          .fontColor($r('app.color.text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
          .margin({ left: 8 })
      }
      .width('100%')
      .padding(12)

      if (this.busy) {
        LoadingProgress().width(48).height(48).margin({ top: 80 })
      } else if (this.pixelMap) {
        Image(this.pixelMap)
          .width('100%')
          .layoutWeight(1)
          .objectFit(ImageFit.Contain)
          .backgroundColor('#111111')
      } else {
        Text(this.errorMessage)
          .fontColor($r('app.color.danger'))
          .padding(24)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }
}
