
if [[ $# -ne 1 ]]; then
    echo " [Input Error] : please give the NN to stat";
    echo " ENVIR : MATLAB SEEONORM TMPDIR RESDIR DEBUG"
    exit;
fi

MATLAB=${MATLAB:=1}
SEEONORM=${SEEONORM:=1}
TMPDIR=${TMPDIR:=tmp}
RESDIR=${RESDIR:=results}
DEBUG=${DEBUG:=0}

if [[ ! -f $1 ]]; then
    echo " file not exist "
    exit
fi

if [[ $DEBUG == 1 ]]; then
    set -x
fi

mkdir -p $TMPDIR
mkdir -p $RESDIR
NN=$1
NAME=$(basename ${NN%%.*})
echo name of NN : $NAME
HiddenLB=$(( $(grep 'm ' $NN | wc -l) - 1 ))
echo "Number of hidden layers : " $HiddenLB
SS=$(grep 'm ' $NN | awk ' BEGIN { s=""; } { if (NR==1) s=s""$3; else s=s"_"$2; } END { print s } ')
echo "NN topology : " $SS
Mnum=$(grep 'm ' $NN | awk ' BEGIN { sum = 0; } { sum = sum + $2 * $3; } END { print sum; } ')
echo "Number of parameter in transformation Matrice : " $Mnum
cat $NN | awk ' { if (NF==2 && $1=="v") printf("%s ", $0); else print $0; } ' > ${TMPDIR}/${NAME}.tmp

cd ${TMPDIR}
rm m?
rm v?
cat ${NAME}.tmp | awk ' BEGIN { mFile = "m"; vFile = "v"; mI = 0; vI = 0; } 
	{ if ($1 == "m") {
	 	mI = mI + 1;
        print "" > mI;
	  }
	  else if ($1 == "v") {
		vI = vI + 1;
        print "" > vI;
		for (i = 3;i <= NF;i++)
			printf("%lf ", $i) >> vFile""vI;
		printf("\n") >> vFile""vI;
	  }		
	  else if (NF <= 5) {
	  }
	  else {
	  	print $0 >> mFile""mI;
	  }
	}'; 
if [[ $MATLAB == 1 ]]; then
    echo " 
        mms = {};
        vvs = {};
        for i=1:$(( $HiddenLB + 1 )) 
            ms = strcat('m', num2str(i)); 
    	    mms{i} = load(ms) 
            vs = strcat('v', num2str(i)); 
    	    vvs{i} = load(vs) 
        end 
        save('../${RESDIR}/${NAME}-mms.mat', 'mms'); 
        save('../${RESDIR}/${NAME}-vvs.mat', 'vvs'); 
    " > domatlab.m
    if [[ $SEEONORM == 1 ]]; then
        echo "
            onorm = [];
            for i=2:$(( $HiddenLB + 1 ))
                onorm = [ onorm (sum(abs(mms{i})) / size(mms{i}, 1)) ];
            end
            save('../${RESDIR}/${NAME}-onorm.mat', 'onorm');
        " >> domatlab.m
    fi
    matlab -nodesktop -nosplash -r "domatlab(); quit;"
fi
cd ..
if [[ $DEBUG == 0 ]]; then
    echo "final clean up..."
    rm -r ${TMPDIR}
fi

