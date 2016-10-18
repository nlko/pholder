export class config {
  constructor(
    public special_char = '$',
    public placeholder_short = '//',
    public placeholder_long1 = '/*',
    public placeholder_long2 = '*/',
    public connector = null,
    public tag_indicator = '@',
    public tag_separator = '.',
    public path_separator = '/',
  ) {}
}
