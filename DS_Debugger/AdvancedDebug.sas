data cars (keep=make model msrp running_price);
  set sashelp.cars end=eof;
  retain running_price 0 total 0;
  by make;
  if first.make then running_price=msrp;
    else running_price+msrp;
  total+msrp;
  output;
  if (eof) then do;
    make="ALL TOTAL";
    model="ALL TOTAL";
    msrp=.;
    running_price=total;
    output;
   end;
run;
