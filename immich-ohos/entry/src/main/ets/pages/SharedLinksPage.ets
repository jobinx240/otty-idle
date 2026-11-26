import { SharedLinkApi } from '../service/SharedLinkApi';
import { SharedLinkResponseDto } from '../model/TagModels';
import { HttpError, immichHttp } from '../service/HttpClient';
import { NavUtil } from '../common/NavUtil';

@Entry
@Component
struct SharedLinksPage {
  @State private links: SharedLinkResponseDto[] = [];
  @State private busy: boolean = false;
  @State private message: string = '';
  private api: SharedLinkApi = new SharedLinkApi(immichHttp);

  aboutToAppear(): void {
    this.reload();
  }

  private async reload(): Promise<void> {
    this.busy = true;
    this.message = '';
    try {
      await immichHttp.loadFromSession();
      this.links = await this.api.list();
    } catch (e) {
      this.message = e instanceof HttpError ? `Links (${e.code}): ${e.message}` : String(e);
    } finally {
      this.busy = false;
    }
  }

  private urlFor(link: SharedLinkResponseDto): string {
    return SharedLinkApi.publicUrl(immichHttp.getApiBase(), link);
  }

  private async onDelete(id: string): Promise<void> {
    try {
      await this.api.delete(id);
      this.links = this.links.filter((l: SharedLinkResponseDto) => l.id !== id);
      this.message = 'Deleted link';
    } catch (e) {
      this.message = e instanceof HttpError ? `Delete (${e.code})` : String(e);
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
        Text($r('app.string.shared_links_title'))
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .margin({ left: 8 })
          .layoutWeight(1)
        Button('Refresh')
          .fontSize(12)
          .backgroundColor(Color.Transparent)
          .fontColor($r('app.color.brand'))
          .onClick(() => {
            this.reload();
          })
      }
      .width('100%')
      .padding(12)

      if (this.message.length > 0) {
        Text(this.message).fontSize(12).fontColor('#FFD54F').padding({ left: 16, right: 16 }).width('100%')
      }

      if (this.busy) {
        LoadingProgress().width(48).height(48).margin({ top: 40 })
      } else if (this.links.length === 0) {
        Text('No shared links yet. Create one from the asset viewer.')
          .fontColor($r('app.color.text_secondary'))
          .padding(24)
      } else {
        List() {
          ForEach(this.links, (link: SharedLinkResponseDto) => {
            ListItem() {
              Column({ space: 4 }) {
                Text(`${link.type} · ${link.createdAt ?? ''}`)
                  .fontSize(13)
                  .fontColor($r('app.color.text_secondary'))
                  .width('100%')
                Text(this.urlFor(link))
                  .fontSize(14)
                  .fontColor($r('app.color.text_primary'))
                  .width('100%')
                Button('Delete')
                  .fontSize(12)
                  .backgroundColor($r('app.color.danger'))
                  .onClick(() => {
                    this.onDelete(link.id);
                  })
              }
              .alignItems(HorizontalAlign.Start)
              .padding(14)
              .width('100%')
            }
          }, (link: SharedLinkResponseDto) => link.id)
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
