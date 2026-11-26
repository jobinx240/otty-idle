import { AlbumsViewModel } from '../viewmodel/AlbumsViewModel';
import { AlbumListItem } from '../model/AlbumModels';
import { NavUtil } from '../common/NavUtil';
import { AlbumRouteParams } from '../common/NavParams';

@Entry
@Component
struct AlbumsPage {
  @State private albums: AlbumListItem[] = [];
  @State private busy: boolean = false;
  @State private errorMessage: string = '';
  @State private newName: string = '';
  private vm: AlbumsViewModel = new AlbumsViewModel();

  aboutToAppear(): void {
    this.reload();
  }

  private async reload(): Promise<void> {
    this.busy = true;
    await this.vm.loadList();
    this.albums = this.vm.albums;
    this.errorMessage = this.vm.errorMessage;
    this.busy = this.vm.busy;
  }

  private openAlbum(item: AlbumListItem): void {
    NavUtil.push(this.getUIContext(), 'pages/AlbumDetailPage', new AlbumRouteParams(item.id, item.albumName));
  }

  private async onCreate(): Promise<void> {
    this.busy = true;
    const created = await this.vm.createAlbum(this.newName);
    this.albums = this.vm.albums;
    this.errorMessage = this.vm.errorMessage;
    this.busy = this.vm.busy;
    if (created) {
      this.newName = '';
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
        Text($r('app.string.albums_title'))
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
        Button($r('app.string.create_album'))
          .height(44)
          .backgroundColor($r('app.color.brand'))
          .enabled(!this.busy)
          .onClick(() => {
            this.onCreate();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 8 })

      if (this.busy) {
        LoadingProgress().width(48).height(48).margin({ top: 40 })
      } else if (this.errorMessage.length > 0 && this.albums.length === 0) {
        Text(this.errorMessage).fontColor($r('app.color.danger')).padding(16)
        Button('Retry').onClick(() => {
          this.reload();
        })
      } else {
        if (this.errorMessage.length > 0) {
          Text(this.errorMessage).fontColor($r('app.color.danger')).padding({ left: 16, right: 16 })
        }
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
              }
              .padding(14)
              .width('100%')
              .onClick(() => {
                this.openAlbum(item);
              })
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
