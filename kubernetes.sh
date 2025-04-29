# space separated list of clusters
PROD_CLUSTERS="k8s"

BOLDYELLOW="\001\033[01;33m\002"
BOLDCYAN="\001\033[01;36m\002"
NORMALCYAN="\001\033[00;36m\002"
BOLDRED="\001\033[01;31m\002"
NORMALRED="\001\033[00;31m\002"
BOLDGREEN="\001\033[01;32m\002"
BOLDPURPLE="\001\033[01;35m\002"
BOLDLIGHTBLUE="\001\033[01;34m\002"
BOLDWHITE="\001\033[01;37m\002"
RESETCOLOR="\001\033[00m\002"

export PS1='\001\033[01;36m\002\u\001\033[00m\002'@'\001\033[01;36m\002'$(hostname -f)'\001\033[00m\002:\w $(kn_status)
$ '

KNS_SUPPORTED=0

function session_marker () {
    kind=$1
    if [[ $(hostname) =~ ^k8slgn ]]; then
        echo ~/.k${kind}.k8slgn
    else
        echo ~/.k${kind}.$(hostname)
    fi
}

if [[ -f $(session_marker n) ]]; then
    export KNS=$(cat $(session_marker n))
else
    export KNS=default
fi

if [[ -f $(session_marker c) ]]; then
    export KUBECONFIG=$(cat $(session_marker c))
fi

function kn_old () {
    kn=$1
    if [[ $kn == - ]]; then
        kn=$(cat $(session_marker nl))
    fi
    if [[ -z $(kubectl get ns -oname | grep ^namespace/${kn}\$) ]]; then
        suggestion=$(kubectl get ns -oname | grep $kn | sed "s%namespace/%%" | head -1)
        if [[ -n $suggestion ]]; then
            echo "no namespace $kn, but $suggestion may be what you are looking for"
            kn=$suggestion
        else
            echo "no such namespace $kn!"
        return
        fi
    fi
    if [[ $kn != $KNS ]]; then
        echo $KNS > $(session_marker nl)
    fi
    export KNS=$kn
    echo $kn > $(session_marker n)
}

function kn_new () {
    echo "not supported"
}

function kn () {
    if [[ $(hostname) =~ ^k8slgn ]] && [[ $KNS_SUPPORTED == 0 ]]; then
        kn_new $@
    else
        kn_old $@
    fi
}

function kc_old () {
 if [[ -z $1 ]]; then
    ls ~/.kube/*.conf | sed -e "s/.*\///" -e "s/\.conf//"
 else
    if [[ -f ~/.kube/${1}.conf ]]; then
        export KUBECONFIG=~/.kube/${1}.conf
        echo $KUBECONFIG > $(session_marker c)
    else
        echo "no such cluster: $1"
    fi
 fi
}

function kc_new () {
    basepath=/var/k8s/users/$(whoami)
    if [[ -z $1 ]]; then
        clusters=($(ls -1 $basepath | sed -e "s%\.conf%%"))
        echo ${clusters[@]} | tr " " "\n" | cat -n
        read -p "Choose cluster (N): " CLUSTER_ID
        if [[ -n $CLUSTER_ID ]]; then
            CLUSTER_ID=$(($CLUSTER_ID-1))
            cluster=${clusters[$CLUSTER_ID]}
        fi
    else
      cluster=$1
    fi
    if [[ -f $basepath/${cluster}.conf ]]; then
        export KUBECONFIG=$basepath/$cluster.conf
        export KNS=$(cat $KUBECONFIG | grep namespace | awk '{print $2}')
        if [[ -z $KNS ]]; then
            KNS_SUPPORTED=1
        else
            KNS_SUPPORTED=0
        fi
        echo $KUBECONFIG > $(session_marker c)
        echo $KNS > $(session_marker n)
    else
        echo "no such cluster: $cluster"
    fi
}

function kc () {
    if [[ $(hostname) =~ ^k8slgn ]]; then
        kc_new $@
    else
        kc_old $@
    fi
}

function get_cluster() {
    echo $(basename $KUBECONFIG .conf)
}

function get_kn() {
    echo $KNS
}

function kn_status() {
    if [[ -n $KUBECONFIG ]]; then
    echo -n "["
    if [[ " $PROD_CLUSTERS " =~ " $(get_cluster) " ]]; then
        echo -n -e "${BOLDRED}KC=$(get_cluster)${RESETCOLOR}"
    else
        echo -n -e "${BOLDGREEN}KC=$(get_cluster)${RESETCOLOR}"
    fi
    echo -n "|"
    echo -n -e "${BOLDYELLOW}KN=$(get_kn)${RESETCOLOR}"
    echo -n "]"
    fi
}

function k_select_pod() {
    pat=$1
    pods=($(kubectl -n $KNS get pods -oname | grep $pat))
    if [[ -z $pods ]]; then
        echo "no pods found matching $pat!"
    fi
    POD_ID=1
    if [[ ${#pods[@]} -gt 1 ]]; then
        kubectl -n $KNS get pods | grep $pat | cat -n
        read -p "Choose pod: " POD_ID
    fi
    POD_ID=$(($POD_ID-1))
    pod=${pods[$POD_ID]}
    export K_SELECTED_POD=$pod
}

function ke() {
    k_select_pod $1
    shell=/bin/bash
    if [[ $2 == sh ]]; then
        shell=/bin/sh
    fi
    echo "logging into $pod using shell $shell..."
    kubectl -n $KNS exec -it $K_SELECTED_POD -- $shell
}

function kl() {
    k_select_pod $1
    _ARGS=
    if [[ -n $2 ]]; then
        shift
        _ARGS=$@
    fi
    kubectl -n $KNS logs $K_SELECTED_POD $_ARGS
}

function kp () {
    kubectl -n $KNS get pods -o wide
}

function kd() {
    if [[ -z $1  ]]; then
        kubectl -n $KNS delete pods --field-selector status.phase!=Running,status.phase!=Pending
    else
        k_select_pod $1
        kubectl -n $KNS delete pods $K_SELECTED_POD
    fi
}


alias k='kubectl -n $KNS $@'
alias h='helm -n $KNS $@'
