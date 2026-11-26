import { TagApi } from '../service/TagApi';
import { TagResponseDto } from '../model/TagModels';
import { TimelineApi, TimelineFilter } from '../service/TimelineApi';
import { TimelineAssetCell } from '../viewmodel/TimelineViewModel';
import { AuthThumb } from '../components/AuthThumb';
import { HttpError, immichHttp } from '../service/HttpClient';
import { NavUtil } from '../common/NavUtil';
import { AssetRouteParams, TagRouteParams } from '../common/NavParams';

@Entry
@Component
struct TagsPage {
  @State private tags: TagResponseDto[] = [];
  @State private assets: TimelineAssetCell[] = [];
  @State private selectedName: string = '';
  @State private newName: string = '';
  @State private busy: boolean = false;
  @State private message: string = '';
  private tagApi: TagApi = new TagApi(immichHttp);
  private timelineApi: TimelineApi = new TimelineApi(immichHttp);
  private cellSize: number = 110;
  private initialTagId: string = '';

  aboutToAppear(): void {
    const params = NavUtil.params<TagRouteParams>(this.getUIContext());
    this.initialTagId = params?.tagId ?? '';
    this.reloadTags();
  }

  private async reloadTags(): Promise<void> {
    this.busy = true;
    this.message = '';
    try {
      await immichHttp.loadFromSession();
      this.tags = await this.tagApi.listTags();
      if (this.initialTagId.length > 0) {
        const found = this.tags.find((t: TagResponseDto) => t.id === this.initialTagId);
        if (found) {
          await this.openTag(found);
        }
      }
    } catch (e) {
      this.message = e instanceof HttpError ? `Tags (${e.code}): ${e.message}` : String(e);
    } finally {
      this.busy = false;
    }
  }

  private async onCreate(): Promise<void> {
    const name = this.newName.trim();
    if (name.length === 0) {
      this.message = 'Enter a tag name';
      return;
    }
    this.busy = true;
    try {
      await this.tagApi.createTag(name);
      this.newName = '';
      this.tags = await this.tagApi.listTags();
      this.message = `Created ${name}`;
    } catch (e) {
      this.message = e instanceof HttpError ? `Create (${e.code})` : String(e);
    } finally {
      this.busy = false;
    }
  }

  private async openTag(tag: TagResponseDto): Promise<void> {
    this.busy = true;
    this.selectedName = tag.name;
    this.assets = [];
    try {
      const filter = TimelineFilter.tag(tag.id);
      const buckets = await this.timelineApi.getBuckets(filter);
      const maxAssets = 120;
      for (let i = 0; i < Math.min(buckets.length, 12) && this.assets.length < maxAssets; i++) {
        const detail = await this.timelineApi.getBucket(buckets[i].timeBucket, filter);
        const ids = detail.id ?? [];
        const images = detail.isImage ?? [];
        for (let j = 0; j < ids.length && this.assets.length < maxAssets; j++) {
          this.assets.push(new TimelineAssetCell(
            ids[j],
            immichHttp.thumbnailUrl(ids[j]),
            images.length > j ? images[j] : true,
            false
          ));
        }
      }
      if (this.assets.length === 0) {
        this.message = 'No assets for this tag';
      } else {
        this.message = '';
      }
    } catch (e) {
      this.message = e instanceof HttpError ? `Tag assets (${e.code})` : String(e);
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
        Text($r('app.string.tags_title'))
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
            this.onCreate();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 8 })

      if (this.message.length > 0) {
        Text(this.message).fontSize(12).fontColor('#FFD54F').padding({ left: 16, right: 16 }).width('100%')
      }

      if (this.busy && this.tags.length === 0) {
        LoadingProgress().width(48).height(48).margin({ top: 40 })
      } else {
        List() {
          ForEach(this.tags, (tag: TagResponseDto) => {
            ListItem() {
              Text(tag.name)
                .fontSize(16)
                .padding(14)
                .width('100%')
                .onClick(() => {
                  this.openTag(tag);
                })
            }
          }, (tag: TagResponseDto) => tag.id)
        }
        .width('100%')
        .height(160)

        if (this.selectedName.length > 0) {
          Text(this.selectedName)
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .padding({ left: 16, top: 8 })
            .width('100%')
        }

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
