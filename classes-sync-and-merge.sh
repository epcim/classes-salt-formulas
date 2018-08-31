#!/bin/bash

# YES - this is very dirty bash, it's single purpose one-time use and forget

# cleanup
sudo rm -rf source

# fetch upstream to ./source
mkdir source
docker run --rm -i -v $PWD/source:/srv/salt/reclass/source --entrypoint bash epcim/salt:saltmaster-reclass-ubuntu-xenial-salt-stable-formula-master <<-EOF
  rsync -avhmL --recursive /srv/salt/reclass/classes/* /srv/salt/reclass/source;
EOF


# do merge
pushd source


# add service directories
mkdir merged
cp -af service/* merged/

# merge system over service directories
for c_file in $(find system/ -type f -name "*.yml"); do
  # strip prefix
  c="${c_file/system\//}"
  # dest dir (+create)
  d="$(dirname $c)"
  # x to test component.yml vs. component/
  x="$d/$(basename $c .yml)"
  test -e merged/$d || mkdir -p merged/$d

  #echo c_file $c_file
  #if [[ "$c_file" == "system/reclass/storage/system/openstack_message_queue_cluster.yml" ]] ; then
  #  echo SET X;
  #  set -x;
  #else
  ##  set +x;
  #fi
  
  #echo d $d
  #echo c $c
  #echo x $x
  #continue

  # add system + merge
  if test -e merged/$c; then
    # do merge
    # merge system over service
    spruce merge merged/$c system/$c > merged/$c.spruce
    mv merged/$c.spruce merged/$c
  else
    # do copy
    cp system/$c merged/$c
  fi
done

# sanity
# merge/move component.yml to component/init.yml
for i in $(find merged -type d); do
  if [[ -e $i.yml ]]; then
    echo "=== WARN: $i.yml exist and will be merged with $i/init.yml"
    if [[ -e $i/init.yml ]]; then
      spruce merge $i.yml $i/init.yml > $i/init.yml.spruce
      mv $i/init.yml.spruce $i/init.yml
      rm -f $i.yml
    else
      mv $i.yml $i/init.yml
    fi
  fi
done


# cleanup
# - remove service/system load of class pointing to the class itself
# - remove system/service prefix
pushd merged
for c in $(find . -type f -name "*.yml"); do
  c_dot="$(echo $c| sed -e 's:/:.:g' -e 's:\.init.yml::' -e 's:\.\.::g' -e 's:.yml::' )"
  #echo $c
  #echo $c_dot

  # detect and remove classes, that points to itself
  if grep -H "^\s*-\s*\(system.\|service.\)$c_dot\s*$" $c > /dev/null; then
    sed -i "/^\s*-\s*\(system.\|service.\)$c_dot\s*$/d" $c
  fi

  # remove system/service preffix from existing classes
  sed -i "s/^\(\s*-\s*\)\(system.\|service.\)/\1/" $c

  # remove empty classes, if any
  if grep "^classes:" $c > /dev/null; then
    #echo $c
    if ! yaml2json <  $c  | jq '.classes[]' > /dev/null; then
      sed -i "/^classes:/d" $c
    fi
  fi

done

# JFYI
echo ""
echo "JFYI empty files will be removed"
find . -empty | xargs -n1 rm -vf

# return to source foldeer
popd

# return to main
popd

# finally
rsync -avhL source/merged .
rm -rf source/merged
