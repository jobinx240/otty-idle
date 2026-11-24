/**
 * Unused splash redirect target; EntryAbility loads Login/Timeline directly.
 */
@Entry
@Component
struct Index {
  build() {
    Column() {
      Text('Immich OH')
        .fontSize(24)
        .fontColor($r('app.color.brand'))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('app.color.page_background'))
  }
}
