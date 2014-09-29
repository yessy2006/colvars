#!/bin/sh
# Script to update a NAMD, VMD, or LAMMPS source tree with the latest colvars code.

if [ $# -lt 1 ]
then
    cat <<EOF

 usage: sh $0 [-f] <target source tree>

   -f  "force-update": overwrite conflicting files such as Makefile
        (default: create diff files for inspection --- MD code may be different)

   <target source tree> = root directory of the MD code sources
   supported MD codes: NAMD, VMD, LAMMPS

EOF
   exit 1
fi


force_update=0
if [ $1 = "-f" ]
then
  force_update=1
  shift
fi

# infer source path from name of script
source=$(dirname "$0")

# check general validity of target path
target="$1"
if [ ! -d "${target}" ]
then
    echo ERROR: Target directory ${target} does not exist
    exit 2
fi

# undocumented option to only compare trees
checkonly=0
[ "$2" = "--diff" ] && checkonly=1
[ $force_update = 1 ] && checkonly=0

# try to determine what code resides inside the target dir
code=unkown
if [ -f "${target}/src/lammps.h" ]
then
  code=LAMMPS
elif [ -f "${target}/src/NamdTypes.h" ]
then
  code=NAMD
elif [ -f "${target}/src/VMDApp.h" ]
then
  code=VMD
else
  # handle the case if the user points to ${target}/src
  target=$(dirname "${target}")
  if [ -f "${target}/src/lammps.h" ]
  then
    code=LAMMPS
  elif [ -f "${target}/src/NamdTypes.h" ]
  then
    code=NAMD
  elif [ -f "${target}/src/VMDApp.h" ]
  then
    code=VMD
  else
    echo ERROR: Cannot detect a supported code in the target directory
    exit 3
  fi
fi

echo Detected ${code} source tree in ${target}
echo -n Updating

# conditional file copy
condcopy () {
  if [ -d $(dirname "$2") ]
  then
    if [ $checkonly -eq 1 ]
    then
      cmp -s "$1" "$2" || diff -uN "$2" "$1"
    else
      cmp -s "$1" "$2" || cp "$1" "$2"
      echo -n '.'
    fi
  fi
}


# check files related to, but not part of the colvars module
checkfile () {
  diff "${1}" "${2}" > $(basename ${1}).diff
  if [ -s $(basename ${1}).diff ]
  then
    echo "Differences found between ${1} and ${2}, check $(basename ${1}).diff"
    if [ $force_update = 1 ]
    then
      echo "Overwriting ${2}, as requested by the -f flag."
      cp "$1" "$2"
    fi
  else
    rm -f $(basename ${1}).diff
  fi
}

# update LAMMPS tree
if [ ${code} = LAMMPS ]
then

  # update code-independent headers
  for src in ${source}/src/*.h
  do \
    tgt=$(basename ${src})
    condcopy "${src}" "${target}/lib/colvars/${tgt}"
  done
  # update code-independent sources
  for src in ${source}/src/*.cpp
  do \
    tgt=$(basename ${src})
    condcopy "${src}" "${target}/lib/colvars/${tgt}"
  done

  # update LAMMPS interface files (library part)
  for src in ${source}/lammps/lib/colvars/Makefile.* ${source}/lammps/lib/colvars/README
  do \
    tgt=$(basename ${src})
    condcopy "${src}" "${target}/lib/colvars/${tgt}"
  done
  # update LAMMPS interface files (package part)
  for src in ${source}/lammps/src/USER-COLVARS/*.cpp  ${source}/lammps/src/USER-COLVARS/*.h \
    ${source}/lammps/src/USER-COLVARS/Install.sh ${source}/lammps/src/USER-COLVARS/README
  do \
    tgt=$(basename ${src})
    condcopy "${src}" "${target}/src/USER-COLVARS/${tgt}"
  done

  # update LAMMPS documentation
  for src in ${source}/lammps/doc/*.txt
  do \
    tgt=$(basename ${src})
    condcopy "${src}" "${target}/doc/${tgt}"
  done

  for src in ${source}/doc/colvars-refman-lammps.pdf
  do \
    tgt=$(basename ${src})
    condcopy "${src}" "${target}/doc/PDF/${tgt}"
  done

  echo ' done.'
  exit 0
fi

# update NAMD tree
if [ ${code} = NAMD ]
then

  # update code-independent headers
  for src in ${source}/src/*.h
  do \
    tgt=$(basename ${src})
    condcopy "${src}" "${target}/src/${tgt}"
  done
  # update code-independent sources
  for src in ${source}/src/*.cpp
  do \
    tgt=$(basename ${src%.cpp})
    condcopy "${src}" "${target}/src/${tgt}.C"
  done

  # update NAMD interface files
  for src in ${source}/namd/src/colvarproxy_namd.h ${source}/namd/src/colvarproxy_namd.C
  do \
    tgt=$(basename ${src})
    condcopy "${src}" "${target}/src/${tgt}"
  done

  condcopy "${source}/doc/colvars-refman.bib" "${target}/ug/ug_colvars.bib"
  condcopy "${source}/doc/colvars-refman-main.tex" "${target}/ug/ug_colvars.tex"
  condcopy "${source}/namd/ug/ug_colvars_macros.tex" "${target}/ug/ug_colvars_macros.tex"

  echo ' done.'

  for src in ${source}/namd/src/* 
  do \
    tgt=$(basename ${src})
    checkfile "${src}" "${target}/src/${tgt}"
  done
  for src in ${source}/namd/Make*
  do 
    tgt=$(basename ${src})
    checkfile "${src}" "${target}/${tgt}"
  done

  exit 0
fi


# update VMD tree
if [ ${code} = VMD ]
then

  # update code-independent headers
  for src in ${source}/src/*.h
  do \
    tgt=$(basename ${src})
    condcopy "${src}" "${target}/src/${tgt}"
  done
  # update code-independent sources
  for src in ${source}/src/*.cpp
  do \
    tgt=$(basename ${src%.cpp})
    condcopy "${src}" "${target}/src/${tgt}.C"
  done

  # update VMD interface files
  for src in ${source}/vmd/src/colvarproxy_vmd.h ${source}/vmd/src/colvarproxy_vmd.C  
  do \
    tgt=$(basename ${src})
    condcopy "${src}" "${target}/src/${tgt}"
  done
  echo ' done.'

  for src in ${source}/vmd/src/* 
  do \
    tgt=$(basename ${src})
    checkfile "${src}" "${target}/src/${tgt}"
  done
  for src in ${source}/vmd/configure
  do 
    tgt=$(basename ${src})
    checkfile "${src}" "${target}/${tgt}"
  done

  condcopy "${source}/doc/colvars-refman.bib" "${target}/doc/ug_colvars.bib"
  condcopy "${source}/doc/colvars-refman-main.tex" "${target}/doc/ug_colvars.tex"
  condcopy "${source}/vmd/doc/ug_colvars_macros.tex" "${target}/doc/ug_colvars_macros.tex"

  exit 0
fi
