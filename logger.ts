export class logger {
  constructor(private isVerbose:boolean){}

  verbose(str:string):void {
    if(this.isVerbose)
      console.log( str )
  }
}
