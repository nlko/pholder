import * as _ from '../node_modules/lodash'

export class config {
  constructor(
    public logger,
    public special_char = '$',
    public placeholder_short = '//',
    public placeholder_long1 = '/*',
    public placeholder_long2 = '*/',
    public _connector = null,
    public tag_indicator = '@',
    public tag_separator = '.',
    public path_separator = '/',
  ) {
    logger('teste')
  }

  extend(config: any): void {
    console.dir(config)
    _.extend(this,config)
    console.dir(this)
    console.log('----')
  }

  get connector(): string {
    return this._connector
  }

  set connector(str: string) {
    console.log('test')
    try {
      if (str) {
        console.log(str)
        this._connector = require('./db.js')
      }
      else
        this._connector = null
    }
    catch (e) {
      this._connector = null
      console.dir(this.logger)
      this.logger.logger(`Can't load connector ` + str)
      console.dir(e)
    }
  }
}
