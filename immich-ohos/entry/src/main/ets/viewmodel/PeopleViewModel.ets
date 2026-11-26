import { PeopleApi } from '../service/PeopleApi';
import { PersonResponseDto } from '../model/PeopleModels';
import { HttpError, immichHttp } from '../service/HttpClient';

/**
 * Named people list for the People page.
 */
export class PeopleViewModel {
  people: PersonResponseDto[] = [];
  busy: boolean = false;
  errorMessage: string = '';

  private peopleApi: PeopleApi = new PeopleApi(immichHttp);

  async load(): Promise<void> {
    this.busy = true;
    this.errorMessage = '';
    try {
      await immichHttp.loadFromSession();
      const all = await this.peopleApi.listPeople();
      this.people = all.filter((p: PersonResponseDto) => !p.isHidden);
    } catch (e) {
      this.errorMessage = e instanceof HttpError
        ? `People (${e.code}): ${e.message}`
        : `People: ${String(e)}`;
    } finally {
      this.busy = false;
    }
  }
}
