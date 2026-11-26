import { TagApi } from '../service/TagApi';
import { TagResponseDto } from '../model/TagModels';
import { HttpError, immichHttp } from '../service/HttpClient';
import { NavUtil } from '../common/NavUtil';
import { AssetRouteParams } from '../common/NavParams';

@Entry
@Component
struct AddToTagPage {
  @State private assetId: string = '';
  @State private tags: TagResponseDto[] = [];
  @State private newName: string = '';
  @State private busy: boolean = false;
  @State private message: string = '';
  private tagApi: TagApi = new TagApi(immichHttp);

  aboutToAppear(): void {
    const params = NavUtil.params<AssetRouteParams>(this.getUIContext());
    this.assetId = params?.assetId ?? '';
    this.reload();
  }

  private async reload(): Promise<void> {
    this.busy = true;
    try {
      await immichHttp.loadFromSession();
      this.tags = await this.tagApi.listTags();
    } catch (e) {
      this.message = e instanceof HttpError ? `Tags (${e.code})` : String(e);
    } finally {
      this.busy = false;
    }
  }

  private async onAdd(tag: TagResponseDto): Promise<void> {
    if (this.assetId.length === 0) {
      this.message = 'Missing asset id';
      return;
    }
    this.busy = true;
    try {
      await this.tagApi.addAssets(tag.id, [this.assetId]);
      this.message = `Tagged ${tag.name}`;
    } catch (e) {
      this.message = e instanceof HttpError ? `Tag failed (${e.code})` : String(e);
    } finally {
      this.busy = false;
    }
  }

  private async onCreateAndAdd(): Promise<void> {
    const name = this.newName.trim();
    if (name.length === 0 || this.assetId.length === 0) {
      this.message = 'Enter a tag name';
      return;
    }
    this.busy = true;
    try {
      const created = await this.tagApi.createTag(name);
      await this.tagApi.addAssets(created.id, [this.assetId]);
      this.message = `Created & tagged ${created.name}`;
      this.newName = '';
      this.tags = await this.tagApi.listTags();
    } catch (e) {
      this.message = e instanceof HttpError ? `Create (${e.code})` : String(e);
    } finally {
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
        Text($r('app.string.add_to_tag'))
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .margin({ left: 8 })
          .layoutWeight(1)
      }
      .width('100%')
      .padding(12)

      Row({ space: 8 }) {
        TextInput({ placeholder: 'New tag', text: this.newName })
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
        Text(this.message).fontSize(12).fontColor('#FFD54F').padding({ left: 16 }).width('100%')
      }

      List() {
        ForEach(this.tags, (tag: TagResponseDto) => {
          ListItem() {
            Row() {
              Text(tag.name).fontSize(16).layoutWeight(1)
              Button('Add')
                .fontSize(13)
                .backgroundColor($r('app.color.brand'))
                .enabled(!this.busy)
                .onClick(() => {
                  this.onAdd(tag);
                })
            }
            .padding(14)
            .width('100%')
          }
        }, (tag: TagResponseDto) => tag.id)
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
  }
}
