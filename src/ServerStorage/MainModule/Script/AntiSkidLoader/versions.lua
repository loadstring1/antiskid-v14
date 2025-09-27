local stable="V14.4.14"
return table.freeze{
	stable=stable,
	nightly=`{stable}.NIGHT`,
	pnt=`{stable}.PNT`,
}