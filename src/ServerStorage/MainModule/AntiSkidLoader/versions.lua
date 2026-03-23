local stable="V14.5.21"
return table.freeze{
	stable=stable,
	nightly=`{stable}.NIGHT`,
	pnt=`{stable}.PNT`,
}