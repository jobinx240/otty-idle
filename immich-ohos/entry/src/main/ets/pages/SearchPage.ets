import { SearchViewModel } from '../viewmodel/SearchViewModel';
import { TimelineAssetCell } from '../viewmodel/TimelineViewModel';
import { AuthThumb } from '../components/AuthThumb';
import { NavUtil } from '../common/NavUtil';
import { AssetRouteParams, PersonRouteParams } from '../common/NavParams';

@Entry
@Component
struct SearchPage {
  @State private query: string = '';
  @State private assets: TimelineAssetCell[] = [];
  @State private busy: boolean = false;
  @State private errorMessage: string = '';
  @State private modeLabel: string = 'metadata';
  private vm: SearchViewModel = new SearchViewModel();
  private cellSize: number = 118;
  private personId: string = '';

  aboutToAppear(): void {
    const person = NavUtil.params<PersonRouteParams>(this.getUIContext());
    if (person?.personId && person.personId.length > 0) {
      this.personId = person.personId;
      this.loadPerson();
    }
  }

  private syncFromVm(): void {
    this.assets = this.vm.assets;
    this.errorMessage = this.vm.errorMessage;
    this.busy = this.vm.busy;
    this.modeLabel = this.vm.modeLabel;
  }

  private async onSearch(): Promise<void> {
    this.vm.query = this.query;
    this.busy = true;
    await this.vm.search();
    this.syncFromVm();
  }

  private async onSmart(): Promise<void> {
    this.vm.query = this.query;
    this.busy = true;
    await this.vm.searchSmart();
    this.syncFromVm();
  }

  private async onFavorites(): Promise<void> {
    this.busy = true;
    await this.vm.loadFavorites();
    this.syncFromVm();
  }

  private async loadPerson(): Promise<void> {
    this.busy = true;
    await this.vm.loadPerson(this.personId);
    this.syncFromVm();
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
        Text($r('app.string.search_title'))
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .margin({ left: 8 })
          .layoutWeight(1)
      }
      .width('100%')
      .padding(12)

      Row({ space: 8 }) {
        TextInput({ placeholder: 'Search photos…', text: this.query })
          .layoutWeight(1)
          .height(44)
          .onChange((v: string) => {
            this.query = v;
          })
          .onSubmit(() => {
            this.onSearch();
          })
        Button($r('app.string.search_title'))
          .height(44)
          .backgroundColor($r('app.color.brand'))
          .enabled(!this.busy)
          .onClick(() => {
            this.onSearch();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 8 })

      Row({ space: 8 }) {
        Button($r('app.string.smart_search'))
          .fontSize(13)
          .height(36)
          .backgroundColor(Color.Transparent)
          .fontColor($r('app.color.brand'))
          .enabled(!this.busy)
          .onClick(() => {
            this.onSmart();
          })
        Button($r('app.string.favorites_title'))
          .fontSize(13)
          .height(36)
          .backgroundColor(Color.Transparent)
          .fontColor($r('app.color.brand'))
          .enabled(!this.busy)
          .onClick(() => {
            this.onFavorites();
          })
        Text(this.modeLabel)
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .layoutWeight(1)
          .textAlign(TextAlign.End)
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 8 })

      if (this.busy) {
        LoadingProgress().width(48).height(48).margin({ top: 40 })
      } else if (this.errorMessage.length > 0 && this.assets.length === 0) {
        Text(this.errorMessage).fontColor($r('app.color.danger')).padding(16)
      } else if (this.assets.length === 0) {
        Text('No results yet.').fontColor($r('app.color.text_secondary')).padding(24)
      } else {
        if (this.errorMessage.length > 0) {
          Text(this.errorMessage).fontColor($r('app.color.danger')).padding({ left: 16, right: 16 })
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
