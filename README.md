# pholder
## Aim

pholder can be used to transform a file according to a database.

## Wait a minute, what about xslt ?

xslt relies on a xml database to generate xml files. pholder relies on a database (json file or your connector) to generate a text file (whatever the format it uses).

## Examples

One can translate the following file 
```
//$ myfamily.myplaceholder1

  /*$ myfamily.myplaceholder2 */
  the_placeholder2_value
  /*$ */
```
into
```
/*$ myfamily.myplaceholder1 */
the_placeholder1_value
/*$ */

  /*$ myfamily.myplaceholder2 */
  the_placeholder2_another_value
  /*$ */
```

according to this json database

```
{
  myfamily : {
    myplaceholder1 : the_placeholder1_value,
    myplaceholder2 : the_placeholder2_another_value
  }
}
```

## Other features
* data comming from other db connectors
* changing the comment start and stop values.
* using user defined post processing functions
* using values on several lines
