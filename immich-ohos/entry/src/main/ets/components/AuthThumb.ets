import { image } from '@kit.ImageKit';
import { thumbnailLoader } from '../service/ThumbnailLoader';

/**
 * Grid cell that loads an Immich thumbnail using authenticated HTTP.
 */
@Component
export struct AuthThumb {
  @Watch('onAssetIdChange') @Prop assetId: string = '';
  @Prop thumbSizeName: string = 'thumbnail';
  @Prop cellSize: number = 110;
  @State private pixelMap: image.PixelMap | undefined = undefined;
  @State private failed: boolean = false;
  @State private loading: boolean = false;

  aboutToAppear(): void {
    this.reload();
  }

  onAssetIdChange(): void {
    this.pixelMap = undefined;
    this.failed = false;
    this.reload();
  }

  private reload(): void {
    if (this.assetId.length === 0) {
      return;
    }
    const id = this.assetId;
    this.loading = true;
    thumbnailLoader.load(id, this.thumbSizeName).then((pm: image.PixelMap | undefined) => {
      if (id !== this.assetId) {
        return;
      }
      this.loading = false;
      if (pm) {
        this.pixelMap = pm;
        this.failed = false;
      } else {
        this.pixelMap = undefined;
        this.failed = true;
      }
    }).catch(() => {
      if (id !== this.assetId) {
        return;
      }
      this.loading = false;
      this.failed = true;
    });
  }

  build() {
    Column() {
      if (this.pixelMap) {
        Image(this.pixelMap)
          .width(this.cellSize)
          .height(this.cellSize)
          .objectFit(ImageFit.Cover)
          .borderRadius(4)
      } else if (this.failed) {
        Text('!')
          .fontSize(16)
          .fontColor('#999999')
      } else {
        LoadingProgress()
          .width(24)
          .height(24)
      }
    }
    .width(this.cellSize)
    .height(this.cellSize)
    .backgroundColor('#E8E8E8')
    .borderRadius(4)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
