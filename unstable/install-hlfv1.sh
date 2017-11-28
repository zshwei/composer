ME=`basename "$0"`
if [ "${ME}" = "install-hlfv1.sh" ]; then
  echo "Please re-run as >   cat install-hlfv1.sh | bash"
  exit 1
fi
(cat > composer.sh; chmod +x composer.sh; exec bash composer.sh)
#!/bin/bash
set -e

# Docker stop function
function stop()
{
P1=$(docker ps -q)
if [ "${P1}" != "" ]; then
  echo "Killing all running containers"  &2> /dev/null
  docker kill ${P1}
fi

P2=$(docker ps -aq)
if [ "${P2}" != "" ]; then
  echo "Removing all containers"  &2> /dev/null
  docker rm ${P2} -f
fi
}

if [ "$1" == "stop" ]; then
 echo "Stopping all Docker containers" >&2
 stop
 exit 0
fi

# Get the current directory.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get the full path to this script.
SOURCE="${DIR}/composer.sh"

# Create a work directory for extracting files into.
WORKDIR="$(pwd)/composer-data"
rm -rf "${WORKDIR}" && mkdir -p "${WORKDIR}"
cd "${WORKDIR}"

# Find the PAYLOAD: marker in this script.
PAYLOAD_LINE=$(grep -a -n '^PAYLOAD:$' "${SOURCE}" | cut -d ':' -f 1)
echo PAYLOAD_LINE=${PAYLOAD_LINE}

# Find and extract the payload in this script.
PAYLOAD_START=$((PAYLOAD_LINE + 1))
echo PAYLOAD_START=${PAYLOAD_START}
tail -n +${PAYLOAD_START} "${SOURCE}" | tar -xzf -

# stop all the docker containers
stop



# run the fabric-dev-scripts to get a running fabric
./fabric-dev-servers/downloadFabric.sh
./fabric-dev-servers/startFabric.sh

# pull and tage the correct image for the installer
docker pull hyperledger/composer-playground:0.16.1
docker tag hyperledger/composer-playground:0.16.1 hyperledger/composer-playground:latest

# Start all composer
docker-compose -p composer -f docker-compose-playground.yml up -d

# manually create the card store
docker exec composer mkdir /home/composer/.composer

# build the card store locally first
rm -fr /tmp/onelinecard
mkdir /tmp/onelinecard
mkdir /tmp/onelinecard/cards
mkdir /tmp/onelinecard/client-data
mkdir /tmp/onelinecard/cards/PeerAdmin@hlfv1
mkdir /tmp/onelinecard/client-data/PeerAdmin@hlfv1
mkdir /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials

# copy the various material into the local card store
cd fabric-dev-servers/fabric-scripts/hlfv1/composer
cp creds/* /tmp/onelinecard/client-data/PeerAdmin@hlfv1
cp crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/signcerts/Admin@org1.example.com-cert.pem /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials/certificate
cp crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore/114aab0e76bf0c78308f89efc4b8c9423e31568da0c340ca187a9b17aa9a4457_sk /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials/privateKey
echo '{"version":1,"userName":"PeerAdmin","roles":["PeerAdmin", "ChannelAdmin"]}' > /tmp/onelinecard/cards/PeerAdmin@hlfv1/metadata.json
echo '{
    "type": "hlfv1",
    "name": "hlfv1",
    "orderers": [
       { "url" : "grpc://orderer.example.com:7050" }
    ],
    "ca": { "url": "http://ca.org1.example.com:7054",
            "name": "ca.org1.example.com"
    },
    "peers": [
        {
            "requestURL": "grpc://peer0.org1.example.com:7051",
            "eventURL": "grpc://peer0.org1.example.com:7053"
        }
    ],
    "channel": "composerchannel",
    "mspID": "Org1MSP",
    "timeout": 300
}' > /tmp/onelinecard/cards/PeerAdmin@hlfv1/connection.json

# transfer the local card store into the container
cd /tmp/onelinecard
tar -cv * | docker exec -i composer tar x -C /home/composer/.composer
rm -fr /tmp/onelinecard

cd "${WORKDIR}"

# Wait for playground to start
sleep 5

# Kill and remove any running Docker containers.
##docker-compose -p composer kill
##docker-compose -p composer down --remove-orphans

# Kill any other Docker containers.
##docker ps -aq | xargs docker rm -f

# Open the playground in a web browser.
case "$(uname)" in
"Darwin") open http://localhost:8080
          ;;
"Linux")  if [ -n "$BROWSER" ] ; then
	       	        $BROWSER http://localhost:8080
	        elif    which xdg-open > /dev/null ; then
	                xdg-open http://localhost:8080
          elif  	which gnome-open > /dev/null ; then
	                gnome-open http://localhost:8080
          #elif other types blah blah
	        else
    	            echo "Could not detect web browser to use - please launch Composer Playground URL using your chosen browser ie: <browser executable name> http://localhost:8080 or set your BROWSER variable to the browser launcher in your PATH"
	        fi
          ;;
*)        echo "Playground not launched - this OS is currently not supported "
          ;;
esac

echo
echo "--------------------------------------------------------------------------------------"
echo "Hyperledger Fabric and Hyperledger Composer installed, and Composer Playground launched"
echo "Please use 'composer.sh' to re-start, and 'composer.sh stop' to shutdown all the Fabric and Composer docker images"

# Exit; this is required as the payload immediately follows.
exit 0
PAYLOAD:
� �iZ �=�r��r�=��)'�T��d�fa��^�$ �(��o-�o�%��;�$D�q!E):�O8U���F�!���@^33 I��Dɔh{ͮ�H��t�\z�{�PM����b�;��B���j����pb1�|F�����G|T��BL�E�8>�� wO�o�v��#ǂ];oV�
]dٚil�5a�aldu5ٛ�?&�M���2��zo�6���L�8��� KGjY�A~`HQԎi9�G�X��6�M�o�1��3��UQ���!�3Y���%x��2��-�D�Ú�)!uC���h��;���t��c�\�b����H�.����J�;Z��3�4+l7��A�_���yA��/DyI�c����/��E��"5͈Ԡ�dlӵ�է@Q釪Yd���/�ry�}y�ZJe�p�.Y��?�:=���M�"��,�E��'�O���?'-�������b!��,YmkF
[�Mw�����!������*-�·OmӸt�G�v���Z?���DA\��"���%:�n��``�I��IDP�0Nx�*�K�8~��;�e�f��e�3��I	�|�u����Nv;mt\����|;���K��X.�I���cZ}�zA��Xs 44���I������t��H�4�ZX1ۑ�{T�i�v����/)#�:MӢT ����56�-c�i��漬��LK�q�O� ご5�TZJj� �6u�4�MyG)y�l��[s5]AKij]dӊ�z�B䣮����!	X�G���Fd��P4�I0	�?EÉ0?����皗ŇE�v�,ܿ~Nb"gP��9�?s�\>C�a�G��4=���a�	8w��������@��c� b偺k(dN:���:��
,�6�'"`����ѡ��َ�y���`�~k��J��� �����bM�؂�a�,x���4����	�]̏І��U>, ?
/A؈��:9*�8P9)e��a��8s�.\˽D*9`�VP� T'|/I+f�h[���� ڠ�0�a�y(��FB��?���l��r7	��{�x=&��t>Pw`�yj�8�*3mU'cd�>>c}�<�݉dz�6H�}}ta
�8f0��Kr;VH��'�䊮��BDv��_�N7�����[쁎����t�8��Ԕ&0�e^���[O��?�؈�[����,a�>c|B}h�6���_���ᝨ���?�`��3�N/ �a�����q���k�WP�0:�?�PaT�@˥�k�)�?H���K����1)]��������S�ԗ��c������[��,<;)=ڇ�3oӁ��L��5f�:�cwۂ5�Fs-���6~L�Ϥs����M��N����*�*[��	��8�W߰+�����E �r��Dm��96r�r��K�?̔ʹ���ˑ��ۼc@��k��Y�6���	��^��,�?#�K`���g#�F����'��:���%��Uy��Ty_��3����R��M����S��R�gW�0Vz���:��B[kzÅ��,����:��֟�����w`�P��ZQ7A[�n��,��QxA�R����MfTt�A��fŃ�K6��p�6Z���E�W��]{�7��,��)γ̲��ؕ�.��� �o�Q���oa���S��bu�B��TP��6�ra^
s �޸����E��HA���r�����Q�����Qa��������ǚ}O�Nh�]����,��P@i_z�s���0���q���8G��e�������.�\�`��?�2�Ǣ"��x�_��"��?ϥ�Y�?\<:a�G������8��7�4�n�@�eZ�ci������P�0C\���9䬋ƣ�o�������ե�~�����D��'�d�Mס���ճK��Er���6 AFXz��7"�٨Ы�T:�	B��r9�;p���
��H��i�u$� ��!��	��p-DO��)D�&_=�	d��U5�ۑ��ht�b��+c��q�ę3��sg�w���A�a��0{@���4�~p���K!����8��J�r�_�?��2�Jf����"���7�B>:嬂x�Z�����8P�w�6���\X����;a+��ޥ�ia������TkcEn�����<�Bf�?��I�O���������?�I��[��)Hiy�^��g�&r<�7 ɹ��^�c��5���2��a�[�Dj�
���e�`�Sy�*��K�����5���pn�_q| | �.pȵV6-��������rlw3�gk��?�`�{����w�dS��Hȁ��k�9V�^��3Z��1C"���Trnք]4N��t�٘$���5he�5& ��>��Y�V��^>`�~�d���%�8�1SBo�0~���ށw��>�?��υ�pz^�? �VGٌD�E�4mg3�I.)�;��I���݀�2"�>�J�a�j�at�[���i��bL?�~mg�.^���=��uA]�S7��C��P��e��T�Ջ��|�r�s0hP��.�1@$�m��K��}������62]�D9��dp?3�A)w(W2�w3�[W<+�x�;�I��ֈ���4���C�l�k����4�\�ĂEp�mR�ϋ�8���߈r���+bmCI�B�M�rJT��o�a���!L@Q�����ʔ*���ѕ�B$3�Am0��bt<���K�/TA@ �w�lG˪H�N���D��Q�	�:�5��R�h#͇��P�(�I���HyC���S#�3!W��2!�֦��J�	����O=~ ɴK=Y)%���>k����>a�l?����<A���?I���)�������b6�m��M��@�?�b�1{�W��)Dq>�)�n���ͼ���1.,�-�����
��i*��~�bv�ةi �-�|��`_�� `H3���A�Pe�Δ	� `��"�x:����j�p��@`��]�]�}j�k�%����K,����!c}��+�#�������t� ;0_S|�on��f���q��o���||���s��&1oz
;g�x����/��<����2�{!��߷�{��w�~�����?����������_P��)�($6�
��b�kuQ�H$b�ZB�8D"�Ę��%��ń�H���$�6$i�?�e��-3IxE^����NG';��YaV�c��,o+��_e��iئ�hn{�+�ȬV�Q������_�'���|�͈�2��[:��?���w�[a�����}�8sda�ղW�i�1F��aB��H�i �O����N�O���]���{'w����r�_|d�wJo�c��/\�Q�ǖ��"�����a������T�6�4X�����)�:��Р��/�"����h���L���,9�ЌF�:>N��{t�YhCjl�Hf�s@�'r�\J�dh�[#�˥�OS)YI5�^.)7r%������}5��㚙i��^�q��5Or�\������ ��e��I6����Y�\.%�CL��j��m�]��r�Q�,{*W�<��>�yZr������g����aV2ۉ��y�=y�l�^'퓲tZ����=�|%#�o���T��NS)�+J�p���_�	G$픦q�����i��/ڽT�8}X,ngz���J7�]*��-
Y�t���9�d��ɢW�|�Q�n.s�?>�N���i�<S�'9�!�zGţ��$���/K:��:�����.tk��	n�d~;���]΋	���N���̎���䶻�{�,�ۭ�r%h�u�����ѩ��Ҹ�J�W�c�ut�K��1ܕw�P-k�����O:��F���y��;3��Fo��RI��e��VM�2�H�H�x����wJ��\��ȧ��O٤Vj�Wl�S�r.ٶN�O撉��U�k�v�:m�9��oq�l,�	��<�ݼlk�{0%s9���rŔh�co�T��V9F�<OHG�H�8yO�$T6����D7�F�FYڍ��«�jf�Lfr�|"����;���)1徭jI�zk�!�)���{yy��#��FcO3Z4����O|�^�8��qx��{ y�`0�[��܄7+���\�睻C�ю���KXP�������?Q�_��-v��v3�4�1��m��5Y�i�Nns=Hl�b��q���^r��"	�U�=fN��C�̿F��#]���4R�K�ECp���J�r���b�P�䫭�,Lş���n>���cF<lU�Œԗ�:���;¶�H5���i��}	P�#���K�T8�F�|�̧3Õ�j�>u�>0��&f�3�����?H$$d����$f^7���Kb�u��y}$f^���Cb�u��y�#f^����;b�u��i�s�k����>�O���IK�o���?������G���'L�����Y��jr/�
��V/�;�����\�xi����9�=+�MWa%�*v�p#6�^5:�}̘�ٓl��A�[:y�fK��i��a����k�;��6��gk�3.��1�Lˍ���7)٧n��|��nń��o��������������' ev����%����	Y�A��٠��P��e�~��^{�����6���7#��05vߋ@ݷ6B �ꚡшY�N�zGײ@�A�J�Q��0U����) y)��'�|@;
���# ��6ԌM�����͛Pd���^,#D�\�V5��=�J�z_-������2z��i;޻���s�yP�[�b�� Cx �C���������������F�j�K��Ӥ�:�I��{�Bg$�Ms����L'�@�t-���P�Wa �Л��G`ԃ}�2y�j��Z��ѣ�ӡ�& �����!I�r9��lL;�׀QZ���}���L��
]���Ʉ��>�v/��J�j?�A+EPց����p�N
��ixc��>�2����B(���W��m���mKS��!�q eS\�d�48tug��m���X����ExP���0����K�F"��ij�Z�۶uW�>B�C�<$M�r%�B>�u`!�CZ������l;��u��iZ���X�r͝�*�ǸB�`KAl�8�\{�*D���?{��H����049�����аK��|k���v�SlK��L��r��r�J�s:�i�˙vږ5��#-҂悸������r .+b.���g���8�r}���f��MuUdċ��Eċ��|�� 7����,M��_�s	(���P�,w�m����4F�9��JУIi��ODl���\1�>@�xRH��R�iYC��j�C�wՇ^-2��5;�� �����.a/=W�H��J~�s����WcU[�4�����a��?�=��59ә�9�@��A��>� ��(;��������R��3���b�l@E�W�@���|x>K�"Y��%]�j:���eY�x�8: ڒ�*�]���+�iȽ�aNk���޲���Ju�i���0cM2��Ր3ߏ?�
p�>������ȩm��b7ߟ���BيK����1�ƒ�"
;���nMo�Gh�[t�&���?tm$��1������d2Al��Sy���V���(|��ɟg��7�����N�:��2��F��������O�[O�5�C���~@bK�7����^���V�U�u��4ԏ��L%2	U�)�Pө�F&�D2-�	2���!��,�T�����(�/e��� �Д{{�;�����u�3?�|�k?���n�S��O�w�=�>�"�Oob��_Qر�y3��7w=�������?��7��}�kb����������>���}s��_A4t�5x^�k���Ε�� �i�9f)[�h����s����`xR���s®��1vݻ������DV�*���;c^Y˻_^��.�ϰ�-��ʊ�ē�B<���IOyK/��abQ\�VLɻ\��%6D���&���v��(��G�@lt�<��y�l�!$�Ƹ4�G��BU�bc��]T��_�`�ʢ<:Lv;�+ڳ.�uĆ�tT���E�ۤw��A56�Sd��r����V�%;R˧�x9n�=�q[�݉}@���@hs�65��WK�N��7���*��̛�;�
�v
�R�/�	���l5�^��X{�0��/���nc����\T��n��[_1t�^O�^��c��m^/R?k1����hw`%S�pd-���?��&��/� �`=��������v%^l�͘�j�(�S�=}��٪�uW噞
G�ҦSҼ�l;�0�0�jU�pz L����b��n�/�;��RӝQɝQ�WϨ��:�r��P�W�O:U��K	��A���~~�"Y�dE�*�a6r��Y�C}!bg����+ʞ�#z0�)��=�=�=�����=B.^O�`��9�W��lL4
��,�`��^��$#�����Ҝ�+�)RCUV)��J�q�FGH%�m)�k����MIʚ��ԧ���ȟg?����rL6IHX��W櫣*e��bUbNV.��U!�&�S�\�Sf��d�Jb3>�Mi�(I�[��6���ݎ�5�t�)eHz���r��sf�8�4�P=84R�^�:Uj�J�9�?��s�y&5�/����n<|��n��{+v/�
���{/<x�������~�{�����_{������|�)�2e{?�ڽ���}�V�/��k�>��><��pܱ�=З�c/�^;p^���{��b?x+�o��"�\��~������ߏ��~����a�_\���+��Ti-�'3��l����e�O7�Rj_9#����y�i2?Gmӽ��=���.Iq.�:Z��g����h�Q΅y����Ϻ\g��l;��U�|�
U�N�i����]�e]h�_ON�XgWd����r��7�i��:�MՒ��������nq���q0PRLn$k�=)�΢�d�L��:�K�!LJ��q��S��L�x$��n��L��.�wy�;�1��>���L�q1�pA�����XI�W#�e��������^:�H�p�Œ��֠���9�6�^)2�3ci�a�� ��A{4:$��v�N��@��	Z���Ѱ�*PBtQ��®s}2>`�� ij{����NJɸ"�f3>]
���"}��o]J49�(ˡ�\�����Y��g�U[��3����[d�@������9dnT���Mq->!r�e�_V��bZ O��0�=<���cץ���1��0]�{@���9��&±�rUJ�NT�6:��3�%�V�Q݂ݚU{\}<nj�r|o�1���Y�\ce�鹍Q/K���i]�1㌑;�{&��V*"o��#2��(󞢜�=�����]�b��h!Җ^�%=_\�u�?�Kw�`O'*:F��S�P�J�Q� ua����@9�ԴB�P+;�V[��fz^��D_pG�iO䋋F�F�Z�L�X�sEC��L_/]�of�D����i+SZ՟<�N�W��D��r-H��|T�����L$�lYH	�V����
�-0� Y���Į{#\$L����[��
	l�aҀ�| P���r��,����r����)�Y�}`vF|v�����L�Ce�zS�)~�ך���d��J�f�2YI���u8($�Uf67��j0��$���n�����[?�\I#�ح�y�X��N4j�pSl(%�bk����e��aI=Y���bF��a�鵘�����GXҤh���{`����ĺ�E��I#���©������)�l�ʙU�"b
���Z/� �m�>��_��U��JT�7^�Nb�2_�R��
v��E��L�V,v/(��W������؞٭�D��{{ٶL+,��9Vr�A�Xi�7b���^��)��ӧxX���k�L�s��z�e�%j���#�,��8�LC�|}/@W�&t�W�p���^/J��댩[ �`U{�g��8a����I��Wh�+��Mݽ��aq{�_FU��mkv��=���m��W�ȣ�{�/dV�a/x�ݥϓ�q�퉜��LQ����H%���IRɻ���H7c���;�9��q�w=����~_C~�7,�/�625\CQ�T| 
�{x�e��a*%��D�J#�A��-?����M�,6�������0߰	Q��c�5{p��v������}�#��YU�6BWl���<~�>�	�F�Y7���l=��V}C��'b�wtbG�a���S�z���)�nz&A���q����|C����Ò������g1m�4��SUR 5@��)�]#{`*z��5́] �3��pl�#>C!���*�?:�q���53U|���|x�~u�͗<s��� ���Րm�Z�F,�<�x����$��}��v�0� ���EC-��C��_=��XGF�sʹ&�Xύ�5���u6��a�"��.�A��1��X/p!P(
������&/��Dr����
v����<P��f(+�y$��V��h�����f@e\�֋�'�5��amj�c"��x�E^d��^T��R.'�/�^Ht̀]2�W�at婇��>��XXS��`�þ���
��z`��\��D��א���e��׿~1&(l�l���>�E�o������Zcߢu+P���pd�dFKȡ!qhg�gA��FA�1l�85ZRB��7'q�\K�V�π.�5��9z��
��	�O�8ЏǶ�U����!N�?ɚj&�l]+\7#m<M)d��������ό3� �D� �J��de�P�%��c���!�Cx.���>J��䙝�Mx-�"^��{M	���6�Aw�)�cx��F��1���J�DD�P�J��"8ѳ�}��7�Ã�g���e�[��#�e AC��P -�8��!Q�.zu�6�#ia�f�] �m:C�����#�&-|h�2m���<πl�ͲKL�7WA��veX
F8�\��:�!�צ�d�a��.�;�x���&@�~��.���Ր��luo~x��Ù (|S����c�A���}�Ed�M���n{���v=!4I���@:ُ��N�!��(�:*�����H8b�C��@�j��G9��>�7��M�$hk�M�T�1�#��D�Zs���<_5
�h���^� '��o(�Dh
�b��݆O|�a�9�5�|cSS~��qKD���)"8oGDw��{�v�7��ѱ^q�o�����Ά8���K���ij;�3�H%���n#�!������1���xZɎ�K�D�����lx����r�9�FFz�%����;*6��!߀�U bGg�w.�/��B�
��w��k�����l�H�J���)I��t��$:�%�~*�W�O��>)I�� �g)U���lJJ&3�D�$�M{���a�-/���c��t ����O�������z�Q�X�p�<�Cm�l ɬ$�hI�e"�!Ҫ����T)+IR*��ji"��h	IVa!)f2�Ւi��R�&${����ω�?R���s�����t=~����߿�h�%��S{��va1(�k_������P�_�jd[mp|`u����|\���!_~�j�L?���l���|���@�qni�oSh�|�X垠��K��&�����k*ǔ�fM��D��.+#����O0:W� ��;�c��ĭ��-x���J\7��LF�tv�6�6pP������7�@l�Ϣi0]Ş��.߁�pζ�=C���$����Ô�QV���"yA��k<��Bt�=Wd�J�ʭKz4��l��Y�P<�+\�*TZOfcc����;��\�Ƨ���[=����j�ƏF^xz-P�9�������Us�j��l媕�P8��N�q ��=	��8�hw����$����*����X֋�sP�ق���O�i1,��䬙2�����\�c�1���ꪼOg3��J��ߖP�G��7�O��ik�0��H0�$
:yQ�H���S��� ���l|7�����u�f�ȏ�n��>!�6�ƪ}���y�~�Q2� ;vKk����& ��q�V��	w�#�=n7ʠ�����R|����c��g�:~>�oW�7y��+I�]���H�s����6�y���ޭ�ͧ��gx�u�?A��w��K���&���&���F�y�wL[��6�.�B�����OQw��Vҗ��S$����t���F�-��~�%�EO�W6���(��}������[Iwh�<��y�y�h�h�~����������[I���ijV���Fd�~:���w$IB��	Z�TIɦ3���2D��Pt:!��M&T�LR�rl�v~�ӗa��H�g���]��[I��޵5'�v�{~�wo�p>]�U/'�|�����(��դ3=�:�t�tg��T*�Ŭg���^�_�߷�$���Ţ5��y�M=v�Hkl/�hWws\���βpx����簍��Y�?۰�;;�[��~���1��	��+|��FxNz���%�`�f�C4�IW���^���;4�����_�t�x4����>|<�?φ��:�Q��������W�&�?�=��I��*P���l`�/�����~��������������6�]�[���_;������4���Vqo�@�U������f�����������hu����m��"�{�g��_�N������G8�����O������m���s�F�?}7��_���Z�P�����'�����߼������O������wC:[9�x��Yֲ��b���i�V?����}ѻ��w?o����v?���|3��(���}��}"k����(s�u�RK�w7��~���Lq鼰��]��en,UG�%Y�B{�3'�nk�#˲�6N�/Nag�0�����{�/k����}v�<ٳ�u�\9����o�G˔bN�:M/��v�X���?�}J��
M�U.�<%�s��s	]���Zю��y �J��$�3M�f���r���r�i�3������m1:7�,�w3����_���D��P�n�����mh�CJT�hD�� �	���+�?A��?A�S����G����Y��]���s�F���g���O�W�F������ф����ë������������O�,�if'���;������KY_���E����G^���]gǶ��O�U?	'���������h�Z��m���d�Q�_lX�UP}UT��J^���YP��x�wX`u�#�0t%{*둿�����S]�<�H� �sI�%�PS�om|䥏��6�u��#S]
ݒ@4���Ӫ�f�m(��v�\�3� �h��`��L2��£�(����\~�Rd��U^��4����Ƙ����������W����%��C����s�&�?��g�)�����I�?_�8,h|`>�9ڧ8�y����9�.H��6 H?�Ȁ	h�'},�����G��Q�?����g��ge��V�XL�h5$K3�t(��n#�-�TtWm}�����%��丹�=Q���W��1���\���vd�컇��<4O�6]n���gV��H�e����%L���訓����ͻ���V4������P���'���M8��������������kX���	�����>����h��}Ԕ�i;���B��h�;�q���lW��
h+���K���If���h�Ƭg\2���^�#Kt�,
+$��R�:�FQF�Tv�V�bwql��dS0E'�"`�ھKC��V4��'���	8����;����0��_���`���`�����?��@#����?��W^�ny��5�QyG�𸙲���+�r�����W������%���e�Um-� ��?p �W=����T:�$X	�*r���; �H���	h����V�[b�����ڨ��
��ޮ,Ku�2 Z�1�Ym*(�K=ϗҹ�ݫz3+�ȷ�U���}7����[����nw �N[,t�Z�Hi�W��7\0 <��F�04:��(�^�^(�$R9ΘHk���e�=o ��R[R{+&�T-?jBB�����4�bJ�2�0�pܵQn~앁ؚʹ�ǳ����H�,��1��V�����GC+��d�$ߤz���{}��Y4ptrY�=m���h���S���
|��x0��\T��_��a��4���Gh�_��}���+A%��~�EU�����4K@�_ ���!������a��&T��p����}�8��{s�� �x����C�.$=~��#	b��!ņ��x!,v~�P�?��}��@�}<~���;���R�9�l�tm�c���,�4�c�d�JM:�2�k�d����ŲJj��[��b�}�;���ݐ�`o��t���l&�1�	����`FǮ�8ߟ$�r��a���6���M8�q���?��T����[�Cݯ�O������g
��*��g�������7�Đ��D �����q����_E����ۗ��vpCP�o�;���W^�������ql�F�2G��%��q���n�;(k����e�[!�%�#�߷�!?2�}ke#�:�]s2ʽ	-<�T�.���w��ig��;�e��b�i<�&+:g�%2�=����'c69���	Zۛ[qL�˺�B��U3}>1.�\:Q��l[���An�\�9���l����qnqsp�#+�"�F�u�m����70���1ѣ���鱗#AWI5%*�L��h�۳�⼒�'<�ܺ-VV���N�b̟�9��EkL�1z�y�N�����γG�������D��in8#��cٕ�	�����ߚP����ݛ
��?��k�8	��5�Z��A�	����o����J ��0���0������$�����s�&�?���C����%� MA#�������_����_������`��W>��?f�_Z��<F��=�?	�%h�v_����U�*�<��B� ��������P3�C8D� ���������+A��!j�?���O?���?*A���!�FU�����?T������G8~��������6Cj���[�5�������� ����Є��Q�	�� � �� �����j�Q#�����������,��p��ш��A�	�� � �� ����������J� ��������?��k�?6���p�{%h����hB������a���������?�8�*� ��/Y�B(�k ���[�5���o>p�Cuh���U�X�2�X�ĸǇ��򹀧2���=, ),�p��xg=��(�f�?��O��&�?��P�ׄ���Ñ:�V@��)����ӽV�¿U�b+��7`���E�/ji����gw �1��Fg�$��-�A9��-q\�C���$e�c�v��.۞Ķ�1�����B���������3��8������G{@����/}�kc�&�e�K_K��U��04������P���'���M8��������������kX���	�����>���o�:}n��h����[�E(uW�y9�\��6><�a�l�/���s�h%F�R��MKu'G�\L�bw��g��V��3;��a�)��ݹ#�{]Hb��Fj�Q�oWåBP���8�����"4���?������
h��������/����/�@���������?�G�?迏�k�o����S���tLJ��l����N���o���������&�d����׏u �?r�w��-����eug;?º8��e?��n6F�v�;�h�`���h�(�V�J(˜�/��0.q?bvTI��gdz'-�{m7���ӷ���G'���M�-�x�,�Hi���;a%�ȫ���hC�s����e~�b��T�C�逴�A9Zv�,�bJj�=�Ξ�������'cn��z#�s��.��ou�kWbQM�$���^���h��9/i��N�Vxܓkt��������+��������#�������C��|��������$N��M��p�A�'�W����Jt��Ƣ�����Oa8�_������)��*P�?�zB�G�P��k����G]9��*��gؒ$�/_�?t�1w�i�u���G�w�v�G[������Y��g�M����^i�����S<Y~�{��x������Y(ї�o�k]z��X���uys.o�%�_cK&�`�Q��iUů��.��m���mI���keLbdHk�d�����w��	�	��\�R#B)[����fJ�y7��q��C&%w<�W.)�S[<�h�'+��}�f/����X1�)��Y��~����o�]T��>s92cQY�?��dK4�۲�B|�m3�ЮI�V!q���(�k�2GFW�EE�Ebُ-N�#�G�������Dpma:��C�A���C<�Z����zba�g�����.2��,1WAe*�خLxk '����^��G���A��"T��X��|'=�]p8Ex��p��m�	�F]f�X����L@X��b>���B�����k����g���L��n~T��������l������>3��ŜX�b�e��^��U� �+7���o�G�����w�h���
4A��,y����������`T��_�����?�_%x���7������9w�Y,���P�є�/�;�ϳ������e�N)�'��f�!������!?��ݬ?���T��o�����~��|?��s�k�%��GFbz-y7�+�!59is~�����n+�`C7֖#H?�]���.%d�bRN7�^����f�!���^l?����J��E�b�YtZҸŲ��I���/�m�ˉ��֥�!�}?!����p��q{�l6c��)K���k�a����f��]������G��6\RI�rO��D]�(4P��B�]���M�ģ��������T2�c�#�[�/`�_�l.|����޹7���i�>���:u�<i��������T  ^E=���@ۦ;��t��,v|UI�(ʳ�w�����JZ	���/����H���!J�"t��!i|����W|��������R�Y{2a6$Z��}�P'檖?P���+Q��΁������uے��Gm���������?��ǒE��K�,����]�?�_�q�kI�/��I@�A�Q�?��BG��.�A�!-�����*�gI��S�[�?BR�A���cg�e��4v��X��{7�^��~z��A�W.��_��(���e��ʺ9�Q�>�Ը������\��feyl�6�s���ʧ��B�_F�����\a�KW.����5ā��G�]G~]	/�e���Z<-fa���v���U��&'r��5��J�u{f�^�/GNg������P߭��4ꮧe�f�mGisn��´�1�ɶ�l���^&������y�G��qQ�<���N�l8{�>4��iS�-U{{e���h��ق�0l��[eh�ڸ*�Ջw��(s���jƸ�6���T��e0�D���U�/ZJ�ֶӆX=t�}���J�*�U�Z
UGY�2�c���X�8��}�CoJ��W.��ɂ�#n���R!���� ��*�߷�˂���O�HS�a"h��D�=��-B�w*��O��	�?a�'����{���1� 2	��������0�����
�e�L��W������S�A�7���ߠ�;���h�ϫ�>K�k����O���C&������?S"����-BF ��G��7��B�o*����_���������$����O)�R��.z@�A���?uc��?2��Pi�����������P��~Ʉ��o��B�G*���������eB��W�`�GJdA�!#�����?P8�H�� �������i�?�������eB�a�����L��W�����S�?@��� �Ў�ߨ� �?���������}��L�?u����J�l�?L�GE&��������a����	��30����oi�p�������Y��"q���)�	�7� L\/�3Z3��23�*�&eX��*�h�dK&aP�aYzY��Д��q����1x���/O���\��0�?^����2�â\M�\����"��2�ʽU��/���H��2iI�@�c3�im2�N��Ǿ0�|��ht˫�lY��_�v��[a����~õZM�<��A����A)(Lm�Т��k
�L��}��j*�[�zc�iے2���S�8v����%�:*�V���+��<�{W'���g�,��P����p��Y �?��Ȃ���t����>�a �p�dA�!�C�ό�x�n��N��Qa��X���Q�0�QԴ�դ%��PZ��I�����5k��˵n��.���kb�_�Da�����bI�owl�Z4
ۚ5��/ыc(/gۅ:r���}�P��
���l��E��E�����W��!21���_���_���?�����DH&��\��"��4�f��G��z�������k凎,�=�����4�����+��Oe�ӗ�>��~�ن��m�p����C�8��M��n^�mF�>��tw�gK<y��V4�o� �f�)��ʱ%ۈ�u��k]r�Xi3��u�]��~�k��ouvg����W)a�
7{�r��x��l��E����4�h��A5��+ܣ쟓�(6}>v~sCT+�c���|�ϧĞO��#�ө�l}� :�!5�V���Vٟ����2����&�P0E*�A�\|^l��5J��R��;0L�2d\kU�m���%Y���P�����`�GFI�����~5���&��0���Ʉ��7�X��4HM�����mz@�A�Q���_��Ӡ�i�T��$0�����G��č���I���bp�����G��ԍ�0�7���P2}������?�?� �?B�G��x�d��7����r�+@"������X���X�	������_�?R���$�C{��P�Ҿ��͏�M�펙�e\�h�t�?�H�<�D�c�G�X��X���1�#�0���~$��+r�~p��m]�~/����~;E'�U;�����5_�ڦ��`e�M���YyM4[k\�'ռ���S�67NX�xr����i��T�Q<u���b?��{I��n��j�xZ;<W�n`�ya�g�P�7[N���D�m�#N�,O\����9c�l�e��������春�� lm���`�DV����[+:�(�yלS+3?ݻ���P���4V��T���~:2��`���ߋE�Q_�{�������GF����!��J&����p�O��������B�S0�����ypԗ�.�����_&���A��!���
� xk2���d|+��T���/�?��ѦV��\�q��Pm���x�K��K�O��"پtO4�ƺ�2���%M�r ���|�(탭T�}���4r^+)�(0�FU�]��k(ڤI�:[�AS���DT��$����@ҡZd��V����ׇ��s �$	��� `I�� t#.�r�=�����qB���p1��2��l�2?����m����������$��kJ{a�Q@�:��ukLt��>w�0��Ʉ�#n����R����8�+q�@���/�_$n�,���Av��*S��Y�b4C+�4sV�uҢq��t�&-��Ke�&�Xܲh��Y�,�Xr�0������dA�o��	����g���g�lϡܒ^�L=��e��'��v{�x�m��R2'a9Y��?n�d�����k��M�T�w�r���%�Ds�.jZs���̩���i�VC� ��٨Z�FcѲ|���c_t�1���Z���C�Ot m��E�P_�;'�?��Ȅ���d ���E �0���K������g��h���ޖU�0ñJaIi��t{�z(5�Τ��v�����	Gz;�oI��*T��s�UA��zmDc^x�Cz���^%��ٱ�vź�fؒu�rY�[h�6�w\G��\����d�����E'�?��{���� #$� ����_���_���e�x@4d���t�"���F����g�W�3r�m�@���(lq�jJ�_��=� �L��c9 �e!��9 ��촕Ȅ[M�������q��tc9��a�I����-Ec1-��azc�?_[j�<�N�V�^��U�4�7�-~����s��%>�׸��y�y��*�h��A���>�@�:���ح��������J�t�$*�^8�-kS�1�����������(6J?��,�cue8��Fz�T?m[<�E�<I��..�MW��MO6v(�ܹ�`Tr�W��ش��&R�־^�(�6���(��9�'F{�6$չ^�N��l0��DqR��r������sV����6���S���L�I�)���ipn�m���L_�܇�������������m�0'q|W>
��������o�*��u�!����X���	O����*���N���م�.�Wc�{����`��?�Ɇ?ޣ0�\�\]v%�f|�OO�/wj������c���l~z&�7����?�KB�q�C0�����������ϓ$��p��=����]����xp����Y��9��7�?s��aN[��;f�����0����縉�iě���I�|�B���\m���_ɞe_�s���;�7���?~��?b��ۻ����\�O��������zՏ�֠+�������r��.����h?����?�}�wnFr�����+�C����=�^����^�o�ܟ�����0KN4��Khm�\���ʜ٦�;�9�p�{���9��Ż�X��y�q��u�έb%�?]�� ؙ�ϵ�����}�!����{���'���n�����|�{��[��V��}uk|tg-=_O�x>��L#癦�?l|�x�?>}y}�8���&w#��/��X�����r��(̟/^������`Ս�~��+��$>;��oLhuŏmQ�~l��B�))�c{vuI��.H��Lᗟ���ݫ.�"9�������                 ���?x�q � 