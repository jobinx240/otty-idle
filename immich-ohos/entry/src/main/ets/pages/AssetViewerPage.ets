import { image } from '@kit.ImageKit';
import { common } from '@kit.AbilityKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { thumbnailLoader } from '../service/ThumbnailLoader';
import { AssetApi } from '../service/AssetApi';
import { TrashApi } from '../service/TrashApi';
import { SharedLinkApi } from '../service/SharedLinkApi';
import { AssetResponseDto } from '../model/AssetModels';
import { HttpError, immichHttp } from '../service/HttpClient';
import { NavUtil } from '../common/NavUtil';
import { AssetRouteParams } from '../common/NavParams';

@Entry
@Component
struct AssetViewerPage {
  @State private assetId: string = '';
  @State private pixelMap: image.PixelMap | undefined = undefined;
  @State private errorMessage: string = '';
  @State private busy: boolean = true;
  @State private info: AssetResponseDto | undefined = undefined;
  @State private isFavorite: boolean = false;
  @State private isArchived: boolean = false;
  @State private isTrashed: boolean = false;
  @State private isVideo: boolean = false;
  @State private videoPath: string = '';
  @State private videoBusy: boolean = false;
  @State private actionMessage: string = '';
  private assetApi: AssetApi = new AssetApi(immichHttp);
  private trashApi: TrashApi = new TrashApi(immichHttp);
  private sharedLinkApi: SharedLinkApi = new SharedLinkApi(immichHttp);

  aboutToAppear(): void {
    const params = NavUtil.params<AssetRouteParams>(this.getUIContext());
    this.assetId = params?.assetId ?? '';
    this.loadAll();
  }

  private async loadAll(): Promise<void> {
    if (this.assetId.length === 0) {
      this.errorMessage = 'Missing asset id';
      this.busy = false;
      return;
    }
    this.busy = true;
    this.errorMessage = '';
    try {
      await immichHttp.loadFromSession();
      this.info = await this.assetApi.getInfo(this.assetId);
      this.applyInfo(this.info);
    } catch (e) {
      if (e instanceof HttpError) {
        this.errorMessage = `Info ${e.code}: ${e.message}`;
      }
    }

    if (!this.isVideo) {
      const pm = await thumbnailLoader.load(this.assetId, 'preview');
      if (pm) {
        this.pixelMap = pm;
      } else if (this.errorMessage.length === 0) {
        this.errorMessage = 'Failed to load preview';
      }
    }
    this.busy = false;
  }

  private applyInfo(info: AssetResponseDto): void {
    this.isFavorite = info.isFavorite === true;
    this.isArchived = info.isArchived === true || info.visibility === 'archive';
    this.isTrashed = info.isTrashed === true;
    this.isVideo = (info.type ?? '').toUpperCase() === 'VIDEO';
  }

  private async onToggleFavorite(): Promise<void> {
    try {
      const next = !this.isFavorite;
      this.info = await this.assetApi.setFavorite(this.assetId, next);
      this.applyInfo(this.info);
      this.actionMessage = this.isFavorite ? 'Added to favorites' : 'Removed from favorites';
    } catch (e) {
      this.actionMessage = e instanceof HttpError ? `Favorite failed (${e.code})` : String(e);
    }
  }

  private async onToggleArchive(): Promise<void> {
    try {
      if (this.isArchived) {
        this.info = await this.assetApi.unarchive(this.assetId);
        this.actionMessage = 'Unarchived';
      } else {
        this.info = await this.assetApi.archive(this.assetId);
        this.actionMessage = 'Archived';
      }
      this.applyInfo(this.info);
    } catch (e) {
      this.actionMessage = e instanceof HttpError ? `Archive failed (${e.code})` : String(e);
    }
  }

  private async onTrash(): Promise<void> {
    try {
      await this.assetApi.deleteAssets([this.assetId], false);
      this.actionMessage = 'Moved to trash';
      NavUtil.back(this.getUIContext());
    } catch (e) {
      this.actionMessage = e instanceof HttpError ? `Trash failed (${e.code})` : String(e);
    }
  }

  private async onRestore(): Promise<void> {
    try {
      await this.trashApi.restoreAssets([this.assetId]);
      this.actionMessage = 'Restored from trash';
      this.isTrashed = false;
      await this.loadAll();
    } catch (e) {
      this.actionMessage = e instanceof HttpError ? `Restore failed (${e.code})` : String(e);
    }
  }

  private async onDownloadOriginal(): Promise<void> {
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext | undefined;
    if (!ctx) {
      this.actionMessage = 'No context for download';
      return;
    }
    this.actionMessage = 'Downloading original…';
    try {
      const bytes = await this.assetApi.downloadOriginal(this.assetId);
      const name = this.info?.originalFileName ?? `${this.assetId}.bin`;
      const safe = name.replace(/[^a-zA-Z0-9._-]/g, '_');
      const path = `${ctx.filesDir}/immich_dl_${safe}`;
      const file = fs.openSync(path, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
      fs.writeSync(file.fd, bytes);
      fs.closeSync(file);
      this.actionMessage = `Saved ${bytes.byteLength} bytes to filesDir`;
    } catch (e) {
      this.actionMessage = e instanceof HttpError ? `Download ${e.code}: ${e.message}` : String(e);
    }
  }

  private onAddToAlbum(): void {
    NavUtil.push(this.getUIContext(), 'pages/AddToAlbumPage', new AssetRouteParams(this.assetId));
  }

  private onAddToTag(): void {
    NavUtil.push(this.getUIContext(), 'pages/AddToTagPage', new AssetRouteParams(this.assetId));
  }

  private async onShareLink(): Promise<void> {
    try {
      const link = await this.sharedLinkApi.createForAsset(this.assetId);
      this.actionMessage = SharedLinkApi.publicUrl(immichHttp.getApiBase(), link);
    } catch (e) {
      this.actionMessage = e instanceof HttpError ? `Share failed (${e.code})` : String(e);
    }
  }

  private async onPlayVideo(): Promise<void> {
    if (this.videoPath.length > 0) {
      return;
    }
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext | undefined;
    if (!ctx) {
      this.actionMessage = 'No context for video cache';
      return;
    }
    this.videoBusy = true;
    this.actionMessage = 'Downloading video…';
    try {
      const bytes = await immichHttp.getArrayBuffer(`/assets/${this.assetId}/video/playback`);
      const path = `${ctx.cacheDir}/immich_${this.assetId}.mp4`;
      const file = fs.openSync(path, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
      fs.writeSync(file.fd, bytes);
      fs.closeSync(file);
      this.videoPath = path;
      this.actionMessage = '';
    } catch (e) {
      this.actionMessage = e instanceof HttpError ? `Video ${e.code}: ${e.message}` : String(e);
    } finally {
      this.videoBusy = false;
    }
  }

  private metaLine(): string {
    const parts: string[] = [];
    if (this.info?.originalFileName) {
      parts.push(this.info.originalFileName);
    }
    if (this.info?.localDateTime) {
      parts.push(this.info.localDateTime);
    }
    const exif = this.info?.exifInfo;
    if (exif?.make || exif?.model) {
      parts.push(`${exif.make ?? ''} ${exif.model ?? ''}`.trim());
    }
    if (exif?.city || exif?.country) {
      parts.push(`${exif.city ?? ''} ${exif.country ?? ''}`.trim());
    }
    return parts.join(' · ');
  }

  build() {
    Column() {
      Row({ space: 4 }) {
        Button('Back')
          .backgroundColor(Color.Transparent)
          .fontColor($r('app.color.brand'))
          .onClick(() => {
            NavUtil.back(this.getUIContext());
          })
        Blank()
        Button(this.isFavorite ? '★' : '☆')
          .fontSize(13)
          .backgroundColor(Color.Transparent)
          .fontColor($r('app.color.brand'))
          .onClick(() => {
            this.onToggleFavorite();
          })
        Button(this.isArchived ? 'Unarchive' : 'Archive')
          .fontSize(13)
          .backgroundColor(Color.Transparent)
          .fontColor($r('app.color.brand'))
          .onClick(() => {
            this.onToggleArchive();
          })
        Button('Album')
          .fontSize(13)
          .backgroundColor(Color.Transparent)
          .fontColor($r('app.color.brand'))
          .onClick(() => {
            this.onAddToAlbum();
          })
        Button('Tag')
          .fontSize(13)
          .backgroundColor(Color.Transparent)
          .fontColor($r('app.color.brand'))
          .onClick(() => {
            this.onAddToTag();
          })
        Button('Share')
          .fontSize(13)
          .backgroundColor(Color.Transparent)
          .fontColor($r('app.color.brand'))
          .onClick(() => {
            this.onShareLink();
          })
        Button('Save')
          .fontSize(13)
          .backgroundColor(Color.Transparent)
          .fontColor($r('app.color.brand'))
          .onClick(() => {
            this.onDownloadOriginal();
          })
        if (this.isTrashed) {
          Button('Restore')
            .fontSize(13)
            .backgroundColor(Color.Transparent)
            .fontColor($r('app.color.brand'))
            .onClick(() => {
              this.onRestore();
            })
        } else {
          Button('Trash')
            .fontSize(13)
            .backgroundColor(Color.Transparent)
            .fontColor($r('app.color.danger'))
            .onClick(() => {
              this.onTrash();
            })
        }
      }
      .width('100%')
      .padding(12)

      if (this.metaLine().length > 0) {
        Text(this.metaLine())
          .fontSize(12)
          .fontColor('#CCCCCC')
          .width('100%')
          .padding({ left: 12, right: 12, bottom: 8 })
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }

      if (this.actionMessage.length > 0) {
        Text(this.actionMessage)
          .fontSize(12)
          .fontColor('#FFD54F')
          .padding({ left: 12, right: 12, bottom: 8 })
          .width('100%')
      }

      if (this.busy || this.videoBusy) {
        LoadingProgress().width(48).height(48).margin({ top: 80 })
      } else if (this.isVideo) {
        if (this.videoPath.length > 0) {
          Video({ src: this.videoPath })
            .controls(true)
            .autoPlay(true)
            .width('100%')
            .layoutWeight(1)
            .backgroundColor('#111111')
        } else {
          Column({ space: 16 }) {
            Text('Video asset')
              .fontColor(Color.White)
              .fontSize(18)
            Button('Download & play')
              .backgroundColor($r('app.color.brand'))
              .onClick(() => {
                this.onPlayVideo();
              })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        }
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
