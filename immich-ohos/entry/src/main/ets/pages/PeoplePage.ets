import { PeopleViewModel } from '../viewmodel/PeopleViewModel';
import { PersonResponseDto } from '../model/PeopleModels';
import { NavUtil } from '../common/NavUtil';
import { PersonRouteParams } from '../common/NavParams';

@Entry
@Component
struct PeoplePage {
  @State private people: PersonResponseDto[] = [];
  @State private busy: boolean = false;
  @State private errorMessage: string = '';
  private vm: PeopleViewModel = new PeopleViewModel();

  aboutToAppear(): void {
    this.reload();
  }

  private async reload(): Promise<void> {
    this.busy = true;
    await this.vm.load();
    this.people = this.vm.people;
    this.errorMessage = this.vm.errorMessage;
    this.busy = this.vm.busy;
  }

  private displayName(p: PersonResponseDto): string {
    if (p.name && p.name.length > 0) {
      return p.name;
    }
    return 'Unnamed';
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
        Text($r('app.string.people_title'))
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .margin({ left: 8 })
          .layoutWeight(1)
      }
      .width('100%')
      .padding(12)

      if (this.busy) {
        LoadingProgress().width(48).height(48).margin({ top: 40 })
      } else if (this.errorMessage.length > 0) {
        Text(this.errorMessage).fontColor($r('app.color.danger')).padding(16)
        Button('Retry').onClick(() => {
          this.reload();
        })
      } else if (this.people.length === 0) {
        Text('No people yet. Face recognition may still be processing.')
          .fontColor($r('app.color.text_secondary'))
          .padding(24)
      } else {
        List() {
          ForEach(this.people, (p: PersonResponseDto) => {
            ListItem() {
              Row() {
                Text(this.displayName(p))
                  .fontSize(16)
                  .fontColor($r('app.color.text_primary'))
                  .layoutWeight(1)
                if (p.isFavorite) {
                  Text('★').fontColor('#FFD54F')
                }
              }
              .width('100%')
              .padding(16)
            }
            .onClick(() => {
              NavUtil.push(
                this.getUIContext(),
                'pages/SearchPage',
                new PersonRouteParams(p.id, this.displayName(p))
              );
            })
          }, (p: PersonResponseDto) => p.id)
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
