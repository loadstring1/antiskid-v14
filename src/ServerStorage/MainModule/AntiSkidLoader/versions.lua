local stable="V14.5.19"
return table.freeze{
	stable=stable,
	nightly=`{stable}.NIGHT`,
	pnt=`{stable}.PNT`,
}