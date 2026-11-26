import { AlbumApi } from '../service/AlbumApi';
import { AlbumListItem } from '../model/AlbumModels';
import { HttpError, immichHttp } from '../service/HttpClient';
import { NavUtil } from '../common/NavUtil';
import { AssetRouteParams } from '../common/NavParams';

@Entry
@Component
struct AddToAlbumPage {
  @State private assetId: string = '';
  @State private albums: AlbumListItem[] = [];
  @State private newName: string = '';
  @State private busy: boolean = false;
  @State private message: string = '';
  private albumApi: AlbumApi = new AlbumApi(immichHttp);

  aboutToAppear(): void {
    const params = NavUtil.params<AssetRouteParams>(this.getUIContext());
    this.assetId = params?.assetId ?? '';
    this.reload();
  }

  private async reload(): Promise<void> {
    this.busy = true;
    this.message = '';
    try {
      await immichHttp.loadFromSession();
      this.albums = await this.albumApi.listAlbums();
    } catch (e) {
      this.message = e instanceof HttpError ? `Albums (${e.code}): ${e.message}` : String(e);
    } finally {
      this.busy = false;
    }
  }

  private async onAdd(albumId: string, albumName: string): Promise<void> {
    if (this.assetId.length === 0) {
      this.message = 'Missing asset id';
      return;
    }
    this.busy = true;
    try {
      await this.albumApi.addAssets(albumId, [this.assetId]);
      this.message = `Added to ${albumName}`;
    } catch (e) {
      this.message = e instanceof HttpError ? `Add failed (${e.code})` : String(e);
    } finally {
      this.busy = false;
    }
  }

  private async onCreateAndAdd(): Promise<void> {
    const name = this.newName.trim();
    if (name.length === 0) {
      this.message = 'Enter an album name';
      return;
    }
    if (this.assetId.length === 0) {
      this.message = 'Missing asset id';
      return;
    }
    this.busy = true;
    try {
      const created = await this.albumApi.createAlbum(name, [this.assetId]);
      this.message = `Created ${created.albumName}`;
      this.newName = '';
      await this.reload();
    } catch (e) {
      this.message = e instanceof HttpError ? `Create failed (${e.code})` : String(e);
      this.busy = false;
    }
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
        Text($r('app.string.add_to_album'))
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .margin({ left: 8 })
          .layoutWeight(1)
      }
      .width('100%')
      .padding(12)

      Row({ space: 8 }) {
        TextInput({ placeholder: 'New album name', text: this.newName })
          .layoutWeight(1)
          .height(44)
          .onChange((v: string) => {
            this.newName = v;
          })
        Button('Create')
          .height(44)
          .backgroundColor($r('app.color.brand'))
          .enabled(!this.busy)
          .onClick(() => {
            this.onCreateAndAdd();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 8 })

      if (this.message.length > 0) {
        Text(this.message)
          .fontSize(12)
          .fontColor('#FFD54F')
          .padding({ left: 16, right: 16, bottom: 8 })
          .width('100%')
      }

      if (this.busy && this.albums.length === 0) {
        LoadingProgress().width(48).height(48).margin({ top: 40 })
      } else {
        List() {
          ForEach(this.albums, (item: AlbumListItem) => {
            ListItem() {
              Row() {
                Column() {
                  Text(item.albumName)
                    .fontSize(16)
                    .fontColor($r('app.color.text_primary'))
                    .width('100%')
                  Text(`${item.assetCount} items`)
                    .fontSize(12)
                    .fontColor($r('app.color.text_secondary'))
                    .width('100%')
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                Button('Add')
                  .fontSize(13)
                  .backgroundColor($r('app.color.brand'))
                  .enabled(!this.busy)
                  .onClick(() => {
                    this.onAdd(item.id, item.albumName);
                  })
              }
              .padding(14)
              .width('100%')
            }
          }, (item: AlbumListItem) => item.id)
        }
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
  }
}
