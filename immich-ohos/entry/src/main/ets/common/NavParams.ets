/** Router params for album detail. */
export class AlbumRouteParams {
  albumId: string;
  albumName: string;

  constructor(albumId: string, albumName: string) {
    this.albumId = albumId;
    this.albumName = albumName;
  }
}

/** Router params for asset viewer. */
export class AssetRouteParams {
  assetId: string;

  constructor(assetId: string) {
    this.assetId = assetId;
  }
}

/** Router params for person → search page. */
export class PersonRouteParams {
  personId: string;
  personName: string;

  constructor(personId: string, personName: string) {
    this.personId = personId;
    this.personName = personName;
  }
}

/** Router params for tag detail / filter. */
export class TagRouteParams {
  tagId: string;
  tagName: string;

  constructor(tagId: string, tagName: string) {
    this.tagId = tagId;
    this.tagName = tagName;
  }
}
