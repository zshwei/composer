ME=`basename "$0"`
if [ "${ME}" = "install-hlfv1-unstable.sh" ]; then
  echo "Please re-run as >   cat install-hlfv1-unstable.sh | bash"
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
WORKDIR="$(pwd)/composer-data-unstable"
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
export FABRIC_VERSION=hlfv11
./fabric-dev-servers/downloadFabric.sh
./fabric-dev-servers/startFabric.sh

# pull and tage the correct image for the installer
docker pull hyperledger/composer-playground:unstable
docker tag hyperledger/composer-playground:unstable hyperledger/composer-playground:latest

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
cd fabric-dev-servers/fabric-scripts/hlfv11/composer
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
� u(7Z �=KlIv�lv��A�'3�X��R��dw�'ң��I�L��(ydǫivɖ�������^�%�I	0� � �9�l� 2��r�%A�yU�$�eɶ,g`0f���{�^�_}�G5�lG�k��X�<hۦg��AW�t>���J%�o<-��_Z�B��dJL|�/�Ĵx	��D���s\�F�kˇ�s2�i���r�mG3�,�.^�8ۇ���,�!�넝�g��ʚ��=C��쨕6j]�u���m�mlǆ�����i�C�P]_��,��:g`�g��U�-��]��.�Yv��`χ�޴,���%7mM���0B&�!v�4���������S '$��J�;'3�[n�3��]��Q�s4��'O���@�_�I1.�)��Ӊ������Q�����t8��l������G�l�k��iN�Z���ܮ狏�����f]����
O�=ݔUl��p�b�T_y	$ܢau�f���:�D,��>����AV�����M-3��Ų��=C���_��b�"��"���!OyA�������s��(jy��BR�܎��Q6Td�y��#�3�h��B�ur\Ӻq�{�qUae�JUY�<��i-��oU ��h�����Ҁ�+�7��M��q:a�����(l��t�����b�Z'��A����d�C�g!kwE�"-B����H�fPj4Kv��#�1*��i��I���8��<�5�q�a�`մ頙�Ǝ�37�E�`2h}��#�+P��99xs�U�cJ�LCP��냋3�'!�-�]�J��p�>�8��y�K;�Un�`��V|%\ձ�`�`+.�u4��L�NΧ(̱Gg�UNtQa�/u�J��ÄX�&�#�ȴ�݅�w�`+*Br������	ܤ�t����;wƀS�G�L4w�w���k�_�Y�T��������hM�8-�Dq*�O�p�/�����G4//Rf��x.ω�)�/$�q��Ë�T2%���0���),O*�C��V.����,� ����l�6uX�C��f�M��y�M�Ӏ�Ǵ��n4�K[{[�z��X�\������Į�/�/= ?�NX��r���U)W/��v����f�V��8k�s�	 �9�3�ކ��@Go
a�k4�a%�7c��'��d%p}i�	�%���n5�zc�Q*7�'s=6�w!�n8&Kun�D�!��@�B�\��#>�y|k�:� ?B�����W~��l�?F�	�-Od5�*�����Ml�ѧ��;4+E�Kdr�@�:��u�I�{8��N,<� ��"���ߎ@6��[�r ���c�B���%N<�_�$��OC�L���'�g��/�<��΢�qe�&��!!�|TX���Q�M�X�H�����'	�ȡ�ipQǁ'�b�E�g���ek��Kxsm�*C�F��>��&��AV��Y�g뤦㺖��Š��5��ٍ�<�tMSw��?tF	ɞ�1m:�� ��?]S08]$��tpD��� z��:���� <䲩�ʁґ5cX㘺G�
#�)&�s����4]�ȶ���C���D�OK�1�2m��
���@�laCņ�� NI0� �D�!7�6�>�X�M��6���-���a�-�>����߬���7���s�e�������:������T2���E�����e��+6�����-�]��C6�j��l��?��K���|�/�����.'��p�[�M��|p��������|��b���?�UA�o+��b�T'���b��
���e�]t�G�d�Gȿ����c�;��*3�j���i����4����/��>��Kx58����ϧ�BJL���������
o�2�`���O��Hө��υ����Erk��َ��m��mdٚ��b�]�P�(G�`#����o�DO�vf>Ж,�NizQ��"D���u�dW%�Êd��B�f}������r�	����$�5U|{�/w-}[��,��Ue��{���N����!	�#���"m��x^5��v�S �9"�֭��qa�x�Z��n��c,Z��I_�##C �u���ŝ��f�8�oa���\Xp:Z�����̢��������VVP��^!F��=8_,`�\^��K�ɳ1'���+�{4�t?M�>F�N�D����b}o�t��2:�����w[A��V�����=�x�$�ȿhEZ�͔1R`����`�B��'k'����fP�3[�\��n��>�#��y����^�D�mB�]��Կp��[!ah�M�gȿlB�1�1L��n���(֓��i��Ԭ#�9�;�cY�0ࣦ���Y69��Cx	�"&xX��"% �M�IE��ˤ�^031�*S��FKk���u���{�f���?0���(���o֋{�"�Ay��߬��֪Rc}�]Ǌ���4]ݝ�D �g�>a7Ҝz�J��-�Wv�tWث�l�ɵ|�cn��7����[ZΜ��­����~�G^M&��O<!&���E�W���<���b9B�哄ET��7�\�Mѓ(7��$r{��4��t���瘥a:"D�(O^@=�p�~��R�l�LG?��M�S:jsf�7����Fʙ��(/~qg��!����(��?�'��?Q^|��Ypt ��AϿ�+����_")��\H�%�il��qQ)W��l+�$�uR�:�z�F�E쫅�"�٭�HI����4Fh|��H$�-�s������"���Z��L1=[���Z�A]y����ku ��Ơʱ�B�W)*�A�lC
Ⓑ���5_�ۘ��m��y�����0�dq~��F_LBȯ�N�}�I}��琜	�M�-ڑ�6�&�؇���pԚX�v5�;�e���8�S(�����a��*4;����#0ɲtM��f�&����F_�Roa�%��$#ot�K/�k*ni�����򛁎��4j����m����轍i'��miF@�}��U�3�38�Am���*oU��'CA�Q�J.r:������Ƞ<�>>�Z��1y5=w��s��m!�Ee��֘�ٜ_�a��ן �����2'�d9l�cz|f����K^A���E�f�y���ϟ�`+��"u��Hq<0��T� � 
���ل{�qM����C�����L��CE� ,׌0��9�|���-� C�g �1���������	�-�*,W͒�,����\,�un<�����6�Ŀ��D���Y�-x�����ó���:��)��tL�������Y�M泉T-��8��͏1��t�WKڨ�E�-<����>*��o��CY��m����a��Ox�EbD�G����2���8pߝ�A��fOؘ�
8U�mY�擯1���fe�N�5TR41br	���[>���pd�ʹ)�I�QOˈA�齟q��z�˔F�|��@�W���lP�g5�b���;>��W�CY���#y��	����-3Lw��r�@S`��@@mIUm�88`	��'���dt��u�鹌_�kz$��Ӂ���K����S�cF�I�R<���Lb�Ҏ0ɳ��l��A����w�(6jT؉�9�1Q�>*���f�w����� Z�]
�Y�{��侏�G&�AjR��D�)���!3Y��m(��i��m4��@�뱭�:K�8f,:vq>	���,�r.�]�f_6`�b�5�;HV#�pυ�����j #��)�����	��@2�6�6��h�c�$m�� v�P���	���9T�)j���4�cd��r����m�R5K�:ӝ�M���ܴ ���%�l�ψcO����h�"x�a`"��9M�_P����<ާ�8����0g�����L�ܝ�Tı�	r p^L8�ѵY+��5����q�/j��e���~�B����dZ���K����)�����q���s��+��g����ÿ:u��8��DB�,�A��l%��L&�jfĄ��qB��T"������$3��^N���d2�G�p?y��F�B�ɽ�����Y˄.]]��.O��Яs��?W��r�'�'�|q���1�p�{��N���B�r�[!n��wa��	`�� 7�����2 -�*�0uL�`��!�����x�3��+ؿ���}���8e�?��?E�� s�������ש��e�O��[�[�ߤ���;�V�������w��ſ��P���������^_�3�+�#���b��~|7��/�U,�r"��Si,$�x"�T�B��)�	�#�P2b'�UA�-y9#�qx W����;?����'����/�~��_�{�_%���X�?����C��!�^`c:���~��,���?��w�����|��Vy����C_��������&�x7BJ��V��|��(���R�Hk�r������^)'�K�½�fgyy����ˬ㤳�����\���s��Y��
�~�\sz\��[ة�֊�{;�G�FI�v1�+o��UG~��P�&��F�A9W�m�~��-�z����� �/V�o�s
��)ך�{Fy+��UWY������f���s&����ƮX��ـ^���ʑ$��w���Z���P�������z��?���ڕ���ې��F�^���JŞU�}зv3�fW�뻽U���{B��h׍{�f�b)b�\?��(�F����+��ݝ����\��vŌ[��zkm
S������Vr6��A���]�0�����T�-����jm���D!��+,8�JG���z�I'v?�&�^�ɮ�lGn�S�.X��cWZݼW{P_�u��:G����-�I��շS ��ȕVy���u�*��c9	澽�-K�d�{ ������V�R�У��ݓz�\�H��p�k�b�]k�ɮ�$���[���I�{x/�똉�a���9��k�:֓D/���Z�ʺTj��~L��ws�r�]v�~fYO���o��[m+�wT��{�q�k�Kk���v2%>��v�Қ�,Z�Tc���%7�\�U^�q�b5�b�p�\�r�5�kR�Ck�Ko�ة�������,����6=��rT�ϕ�f!�r~g��/Iu���F���i��]�wO~P��K۬Miv�M˭qJw�F?�������QKϣ�h���Ύ�]�n'�LFʇ���m㋕�_l06�Y��6�l0p5��]�(���u.�/�����WTMQ��]�m{���Re�s8��<��=;�d{�',LQb�����F#��E�;��	�}}�j��6��OLj#WSM7��2��2�4e�J����!�c�5朔�JЉ���r�u�O����m�d��� R9U��+�P	�D��o'b�Ed��6����Qi�3L��hli���֘�)aYmS�j������v���u�^��F�*=��D�h-G�զ�����>6M�����=CH�����m-X���U��+";fY���z������27[����ۍIR���3�se��\#|�RCL!k�moTvq��c��,����e�'��NA���������2-Ȥg̭N�e���� ��b�)�ᢺ��('*Co��Uk-	�<��ۡ�i�|C�྆�0j,V�2�����y��Bv��#n{&�f���4m�L��|v�\���7p�ZCiw����>�J����C�ƞ���JR;� ��q7@����t�?��hQ�9Җhe��8�Q����2;�x?�V�cհ��b��6\AHh�Q��Ġ�L�L��F��2Y�>�S����%�Ѓ�y�!b:��=��X4%jM�ԥ�2��#}��6�4�ږ`�(���3�Ȥq!���V��{��
JNx��5hv+L���D�Y�Tg�i��4D|��'��϶j&����|6~[�ˣ%���������/>{��Խݨ��ȭ�{�+N����8;�?A��Y�p��p�������K_���-_�������������/����|ߥҋ�{�����N��e��.}�W�J��]�A�3̥����������m�_�-�˷��Ӄ��(�5G*ڷ1_�+ۦ�\����H�{��w/b�m~�_X��y�~�w��5�bB�]������f�<O�=E5�e.蚺�Dn�+��3pO�:'n��{W�@�D�L���&X��m�P9.�x���06j:w@�5zC�R�-�:�!�jֶ>df�֜!�ӯ������K�����h)%�n@�Qŷ�YU	By�th%�z&ۼf��U��
�v��H�cs&\��Ǭ�����dS2��*�]
�r<g;�ar,�lǗ�|�Lӱ--VG��~�X�,V�Ol�I��+p"�a��OZ=�A�Qg6뢈��hb�kD���G�I'q��	T�9]"�.�(<��ވ�z��vް�B���Nx�����Mz��z���Pv�BY�+�,wf��i4�J��Q�p��<�wTN>���}�\=�ݓ@f���s�∞`��*���X�k�d�M�c��1�|,��Ʃ�CO���]i�1ۿy{G�W�8�t�Ko¡�����0�B�ڊ��=m5ZX_�̍��|nxZ.O�P�,=�P�ĵ^<Hڳ���J�[���	<�X��4M�B�Ǫlr-��k�̫,�ԯ;˘��D^��5۩�"�[�Tk�m0�7e���GO���q���xIQ/B�q��m]������J˓]O�Y�3\��Ao��}9�٫�*�v��y�0�`�&���"���|�Ģ��Љ��f�:��(��契���>��i ��U�����e��pd��*I!�@�H$�&��'�8��:�J�U0��:s
&Э~c0��v�Lک�?��}<���;]��/�55Z"�"�Sk&2kQB&K��X��*ہn�&����,c�5����Q�Ng�I��P�lC�r�ӈ�Ԁ�"���4��
/s�j~HlmG�D�-\�����v���&6���{�{(6j�F�CB!ug�A�a�b&��1���A�#=ta���;��%Ʈ�l왓����2a��������)L��:�Y�ⷺ�J�?j��wt�ץ��J��E�Y7��5��d~�����oo�hۋ�ux5a�^�N|�7�/��\om�tM�җ��"��)?@q^rR�M�/�o~��G��?������C_�]�R����9v;��Я�t
�kO��������lң�R����ojv�nY�N����f���n(�|��~wu��7�zs���~t/��_�O��on��D�^B�}�2��z�\>��g�� �O���ɒҷy�w��CP���	޷�\�}�5޹�qAq��Yࣴ���=��q�	^���?5��߸��=pg��U[�����O��04������~~�S����M�=�����_ת��6^�,��	�O��?���(���}���Ȉ��k��Ӆ ��?���������3An��ֱ��� ��ϝ�1��G�g�\�ߵ]o�A�x" ��ϝ�q���B�k�]l��૥W��OY���?��]�?��/�����6�%m#��aQ��>��� �/���0���\��������`�7��/�� ٠�A/����� d�?���;`�(��C�K�O��r��4K ����[���	���c���@Q���!X�9
�������?��� T�ն@���T�ʻ�~B���r�vz��<��������sCQ�, ����`�?7��0����/
��远����x�(^�=��s���[���q�b�?������.����8zH�.C`45t|�׷�>^!=��x�KP��;�}|�$<�9r�P䟣�����Q�ǩK�������j�ݣ-��.�O�_���Ⱦi�`NB;����3�:�8"8{��C�F�dsY�h����/�A�E�*?j��t������a{��)cenթD� �wM�N ���
�la�m+�1%��[AU�)t�I�9ޛ/WK6���^�7Mf�K%��{7��^0!�����!��O��oP���_~(����!W��~�WG����lQ��/?|H��ف�I�j��Yp�C�������V������M\o��q�u�;i��9�9�z�FV���3�7Б7��v�W��Ն�j���~g��\��ci2\�kn����هr���mQ���`�7'��]����?՟
�������@����?@��5�4`~(��#��G"@�e�G��_���kjA��.�`a��r7�DΠ�ON�U�\�ݾE��r	]:���۠��m,"���h[:� d���ͨf,,���μW�+���=?��+:B�!t(/��Q�-�ެUG�6�R��p�ۺ�*Q}�n�b}��Je�kuv��?m�*��ᕖ3:�u3k.���
Wi
I���N-mw��҂�u��E���X����|w%tG��G�WeC�E��AW�9��[U�>��d�Y���l&�٤�ㆻ~%yH�V��(J���h=4�J���]6;�J�������f��'����%X��_&�����Zhd�����!������,P�'�P�%d����ka�����!��� ����?��Z8d����+��`�W��+��������.꿂��2B&���RX ����_�C/꿂��!k��������'Q��� X������`�?��@�}4��y),�������~Ț��>/�B!������g�������|Q���`��������	��Y��S�?��f�B�?}��
��g������ݹr���y�?�<0�K����?(�7 ��ϝ���_nȟ�AfH� ��?w�'.����2Bq���䁬��]�?�`��L �?������������� ������?o�W�'A�_^(�?p��(�� ��?f���� ��w��QV֢^ŬΥJW�S�u>)�_>��O)8��ж�=ug��)M�M9 ��/���6ZU��~M��u�+�`�0E/e�^6U��6;4nx��vQA��ӏ�#�`̭�j8�4W��it���@i���@ițr@�	���ݪO�#F\�:*�[!G�D�h���VU#f;׶��̑3�$���bIvk˭�����*;~յ�͟��gB���� �?2A������?o�W�'/���?d�B�?(�9
�������	@�GP������/��C�	�����+���
���8d�(�������A���B�?� �/'��&�>�k��< ����E��������@���`ڵq��)۵���q��|q(�AI��0��x$���M#�O��CSS��!E�9�X_�OE����� �?������=ڢ��b������ʩ�_I�J0��%��y��5NB;�����������J��D5w�F����?�z��)��l:]m���E��۠�.׶�Nmy�כ`2�B҄���2�m[�n�
u��Xy|贔8�I�ah��A�}�REٷ���n���M���E����g~�7��S0�/�������P�#7����/��h��,�#����������fj��U�%)<D ��5洹�5⪆�}x�%a��N��2�=��+l�\
D���S�O�F�"�e�7�.�C�.��0��a�7�Kŋ���smí�"Z�g�4�{�9����(F����B�$��Y ���گ������,P��_ �+7��/���@���/���sA�I�@������꿀�����������X[qg��/�u����M����V:%��(O�hcOE*^ٶ^�CzYV�$Ҍ�tc;�dT�����M`�*t��(��6G3����� �F�]F�SC+���jr�1�M?�yP��8�Mj�����U�'}��;��޹5'�na���b���p��6 "���q�������NOO�N2�������6$�H��z׷�X�r��*ܶT���y�أ�����럿��Ɔ����;���a��Ҝ�c�e�CK�K�s�d[���\w�i����f�_鉮}����x{�8@"��*� �;Zbm�H�F�e=]����e柭�I�R�z�n�e&rE$�S�HxG���ihh~6��	m�D��u��4?p���,�����?�=����/P����^����s�KP�� ���/����`�����g6����y�R�$oG�{��%I�L@|��׏D�� �	�H���B��]�G����?���+����ڨDb��@;��$(�di4N�]��Vًqpb�H�}����a�-j�>�@��[���x��g8��(�t���M^u���@���!���:�?ɼ��eq
����oS<*��'h2R*"���4	)N�8ɦi�є���I(A�GD𓨃�?��b��!�W�������z.CS�x7��m0?$�S��=�ɩ/%����r������+ߪ�����Z<�q��*��6{�T����14<�Q �_���__�����&y)��������h�������|�i�����(�����:�?�y��������W�����@��?"��O��?��$ ���n���!P)���������/P�����������+��_�����ʨ��G�}�w���W���r�g^�@�Q'���?^~��>T�����W����/���k0�e1Y=�Z��7�y��_v-a��[J��9s�b����R�RvF�Eq��7��8ɒi�vx�1Z1���x�4�׊�L�%�]����c��ؚ��7����SsR��9d^QE��?Q9�*��o��L��>�#u`؏�`�u`��]~�;Iן?:���ìHL9=ղ=��Ű�G�"�ŀ$؉�����_��YZ�����m���Kg;�q�[S�mm��2ً�^g��Zcb�K�m�Ķ<&�����i`�f/[�S�W�V�%���,ue��S�W�����DŤ��7�s��s��-�ۀȋ���ъ�25�/�\�d�W���+��0�4���@���d�H��-���e_��-�|�͛Kw��&���{�$�K�Ҙu]v��6�\�Qkr1��L���2r68zCwo�����uz��bg��Q�Aj�b���
�j�=���H�C�W̲5d ���׎�j���Z�a�3���/�$��Q�O��k����H���Wo�?�a��u�GV�7%����Y�,��W�_��W���8~��RT��_�:(5$����5�����^Xj��2����:i::�stһ�6z~��Rx�e|4��=�2~He�����e�]M�>��q�B��q]��o���.NC���#g�gÛ3{�5�<��Hں��F��v�I`�F;���cr>�o�o9�0����rV�Ҙ;��5EZŞڵ�n�V�Z���Wq.��m���:�,L�ui��'钀���4V��j�Dz���p�͚3��htL1��c=5��h*��d�0,&+�6t&	����t�7���$õ�#�(��Lφ���+�s��v�lE/M�;�����>;˴�c˵�߿��-�"�{���u����@��������<����O$�L��sb ��:��|p��ߐ�3�?l���������!lA�_ֲ||i���������?����nCT�[�?�����h�� `/¼��Z���g���3m�]�=����ָ�r�u��n�',j?�|�q��yyl��i�"c� �qG�m1|��,�vڷ�e,��;��7e�̀�y �\�: ��Ŵ!����*��2�Œ�z�8��D��:[R�������u ]Q;�B��J[`bE3S�
�m����˄ٙ���`�.���xl--mA&��3F3����.�c1���t����ȳ+�wI�"��_u���ۇ��W�����B���WF��
 S������p����j���E�G<��$!�CA�Er.��.����_;����S������P+�'�k4�	ǆ)q<��)/$iD�|$�$�P��q�G�G�s�\M3l�{7u������#�W��q��v%#�5��"d1�'��!1N,�[.��v+�.�1X��o����Q.�eoLwqi2׸�蕼�a�a�h�6sf�˄qG��2y��<?8=2!�Hl��ù��<Y%�9�M����:<�a�guT���/�зJ����W����Qu���7��j�~7�u����+�_?�L�������Xl�覉�����V���&���Y�(����s��~x.�K��5r����lyh��Ǭ�&г�D�����NR����t�9�⶿5[�En�I�S�~hm���Ta,�o��
�Q����~�7�_@꿠��:�������� ��_���+��N>��C����,��=��W��R'Q�'���p<(�G^���<�k�:���v�Ю%����p�8��2��t��b�D�F��,=�&�0�5���V��f�Vđ=4����<��3";3��\�\��6�
�:Ϻ��/��s�0ռ�^�v^�흾���u��ඥҔ�vR����N��&��f��Z3����GR+��~�I��*�y��=j�+,�5����h*Y׸S�n��9=�D8�Ԍ��}�<��թ{���� 4���7ę���"�B7�u"��}#D2�6ژi$�-�h���m��}{��] ����X�ZcP�������?h��@B-��}��P��D��]k
�?���O4�E ��Z3P��{��Ұ�	������W��Z��U�	���@�������k�u��$���"��?�x������i��G��C�?��C�?���>1��/5��׎��������Ê�:Q��h��� �_`���W[�D�?�~���_������k����	��#��O������(@��p�_WP��{��)������������J�?����E�����e�0q�ǹ8�	2�#<� `YZH8�g��
��62�H2慄�"`��}u����?PP���_����E߸�d5�cf!9��e���ڎ�k�t>`�o��v+o2�/���׺�㇭����W����V�n��Ie:譼��E�^J����A3]���Nh���z8�j����R��?���O������� �	�����?�A�u��x�����L��������w����?H��?����?���6��@�_E ���X�60MpO9>&��Ax�%q	OD	��|JE�Q!G�I��	A�AG �B�����4�(����2m�g��l�/��A�b���n����	=kzTR$���<���v�ln��V�bť�692k�J��~�c�}�����$lbO��)Z��nؙ�w���M��<�p!9���Z�n�����J���������k
�����?��A�I�A���G2�������Bŀ���W�����	U�?,��������x����AB�6CT�?���ϼ����#�N����A������� �`��������a����vCT�����B������G$�K�_I�ϣ�����?"��������tN�s,'{1eI�,g}�͝�����_���}���:K��M���{�g������P&!y��e⥶�4�m�l�>�Ȁi�ޥ:��o�r����꒞��|Z�z�ylJ�&�.���P]۬e�J�dﱿ��D4����+���)��q��sI�z.���c�>��6~x���@��=#����;�yg��뤕'��taN��dQ��Tu\Ň�L�9'�-g�IK҈��1�F��VE���g�|d�V�d���p���/ �?�Q�����U�_��_;����3��	5����:��G�h�?
`����O0�	�?�U�?,����r�����_-��e�L���/��u��p�_?=����G���E��[���9nJ�9s�\Y,/X]�.f�������hd���h�Mt��k���՝O9��{�X�F׏�$�V���]^&$Rq|� wU8������p,����$~�Zbp��tҚb���KmY���\'MG�{�Nz���O��ϯa�\
o����2��\���?�e�<{x��8K!���M_q]��o���.NC���#g�gÛ3{�5�<��Hں��F��v�I`�F;���cr>�o�o9�0����rV�Ҙ;��5EZ�n�u?��[-k��U�MILyE���)O^_/S6D]Z����I�$`;��(��v�&��z;\n���0S̿�X�['�x&��+��.���J��IB��E`<�9]���3�p���H8�q3ӳ!c����㼝+�@�KS�Cl<2�~���2-p��rm��o�"�#���G$�!�[$�b��p������:�?E>���	���8	.J"�p���	i��A<�C>䢈�"����H*�p*b#��Op��n������G¯��_\��1?ͤ��l7-+�?�.�i��u,�y�o���=kw9���_�%��x�/���./��6`�yxf�Wth��&�0&Y�o�*I�tclp�׽�r��R�T�*�J�b�"��om��2�^�jC�c�t�vp2���Te��2<<�.>_��/���L�g[���Դj�䰕lM���ƉAn��F��N��u��U�KX���?��<�����C��,/a�_����������l�%��q���M������z��|�!�n��ujo/�O� qO��|i��?�8�j�q~zz��:�6]o�W;�䛵��A+�hcj�?l��h�[b�O:�R�\�f��d{`g�f��c��T������n��h���J��q��<�&����z��jy�f��}�������#q��������|e}�k}�k}�k}�k��Y����Yۀ�P^���������{����;��� ?��o��^�D�;�\8���jZ��ˍ���Y����T/��h����?s ����HО]x LUe��Z����@���of�'���C��|3��E����GZow����q��T�{�oJ�����xX8�\��o��ګZ����)Xo���v�1F�Se�/��>�0�?o� ��'Ge�X�Am��g�t��f����A�5�.?�����7�����F�A}k���4�F���>�D����Q�me�(맟��S��DʟE��7��Q��R�}<HX�x7����)�_��5�K�Z?4"f�������>o���9�N����N+�|IwF��~�������dpUn����_����h�'�|JG��>���|!���t.[X�����"s<����!��|��qR�u��g6i3�j<�*�tZ�ϱCMa��bu���טU$�1U�,��'�T�=\hѦ�2�[v��H��5CC{��}b�2�h� �6�0Uf?0J|�B8<�i�+z �j��fI�l���o�팙�g��i	��&=���7-��Fg#0m\��>6�"����7m��đ�����we.F�QX����w�zT���g�;��xl�}4�'`?�J��f�)�A�0��t���X��	����&�A��kIxb�v-�WqB��qA��d����P���G�ˀ|�a�4
6��A�e�)v�/�Ҙ�k�̞M�o[C���31	,�*��՜��;����M�r��/|PX��)_��� �LC�ƛ&WT���%�9rx�,3
�`�X��P�� ��V0��	N]�y'fG.�(vg�~��}�o�����w�5���s�.������[�#�c�A�l��@�}�#���h�L�����v~���	ϴ��}J��䆷(Jpơn���s��Pћ\��*֣60��q���ڃ:Q�Q���O�x�x�L;sb󅖋RH��P4F�Ť*q�H_�V*�쫋F������2�)%�i^�_킑(.g��FE�$*���N,��Ӆ�o:�K��pG=XC��7���;�x�J�P�y�����/�.�>�ɱ\��QT�xs��`���u#J�T�H�t��u\$(Ewm�"��88���P*�搰w
{e6@�bt\/�fDǹ�@�h�`�͇ǑWL]�l�H���8"��HR�+H7��Hr���ȀvkY@���k�X�i����MO�Np�{<Y�4�8�VB���Vc��\�ΐ�x��Gwn��l���WM�Y1�[Ƨw� ���s������l:�d:�N���I
�8�f��N��D�`s�yhAf�Zڈ@���1�t��'$�(��QjW�A������b�f$3.5�4а���vK�v�rV)��7�j;	�(��`%o.hة�?����Q���Vc�r;�hخ��v@��q��CS�����"��J�r�X�K��I�Ji-`^���@��i/���^/��JT���,�$�6�4��n�Br+��2���+ͤ���6�X��);�/H�Gx�"�;�����S�����+~�S�&���FN��F-��Ģq�Tʝ�M��o�����-����v��ܫ5j����as���v����;��Z�ӭ5J�j����$��߭���N�sT��7�;�)˪��� �s�k�؀�ϲ�=������:�zuG�������z�&
x�[?s Ӻ �Lլ"I�c'10��&lKI��q{��n�YXx̀KkN�Aԓ(��E.X�&�z�
UK��;��Y�N,�G$��^�)�/><_����.a}lt?��4�5d��zc�l��
��R�QiV�Vk哽pՏGg�F�լ7�;��]��B��JX�!��dT޲U�ּc�ẞ��BV`��ܪ��4�ov��fc��w֨u?5�G0�O�΂&m�ӐRA�U��z��ݿ)<��/5�Y�U��m�[����j�[*�:�0�a�|G�J�_-�1�o�l�������J����V|S���
<�r�g�QN�����I:�$�O2����U�0���Fx��7����엻�+��CW٘�}F�O���R|'yՔ�.��sY�nE䁸M��2�;(�j��}]9�5��q�y�Ĉ������g)���͉c�\MW���J[K��l*;w��-d��OR�+��%h�*&5�N|�Y�]��;�ݽ3�Tm�>U#�vDp �&��T$�H�qO�$f���u�hw�.[l��	�2���tT������U�"��s�J������Y��2��e��L!��r����ȥ���e��Y������g��Y�������y�?�z��ӧ���h��Y�{��{�����jN�]�6nW�cY��B���J�@��Y<��d�������[������_�H��5�v�,�zGƖf8�꺧��xc�b�T��S�~r-Aa�����b�"�=��x���ZF��
�Mk����xC������n|�5l���<iWj$�����(��W2���	�v�.��䰫�B��";"Wmn<��:z�+#"p�ꈄ_�XQ
@|�k��b#�RĪq��˚�"�,��Y}��D��4P�?�=	=�q��5��ƛ�K���w������.lM���H͆uB�Qcu����ێ9��ǲL�s��L��i��t>�Y��S���'Q"�uį9�|$�)#� �6�������w/���
X�*�%�ˈ���L&���Lf��?I	��B��%�Ć���&���)C�D�����w(�x���x����W�F{q_�.zb �:�ȴ`c���?�?�����R�PD�c`���zL���3�aȻ3��h�!��6�]F1ԁj�"� D���37P���Ij�4NE�#��lvV�.nalA������W$6pH���`����f�H6����Ǜ����a���m��	|��o���_$6��w�^��Z�͛�.��T�k�6#�1D��f���lw�:d6U�?	H�p����4��G$��a��1������!Q����|��i�i��v�����N�V�L�K�`%�
x��)��x7����e2���P� K�6���\��끁��c1���\��n���P�l�ߧ�D�˵p�sBm�/��W�
Q��^W����>�}��q�{���n�d:�Z�5�A|�?z���/\��Wu���������@�&.b�%�Pɺ�$R5��:��e	:Hܐ���=�5w��$��hj{�?�M#򝷉"D�$���;�Й�o>�|���o��IԵ�(��k�	�W`�k�U��k^�/	A��V6A��h����a��#z-!q�Q�=$�Q����I�0�7oT~�q��Ꙩ_{nH├�>8��6���*���M��ڈ��o2�$��+P~"1��A��{��|]��|p�G�R�,��$+�{��R��$��[۬�d{[�v6�a�T.��ҤƈBS[��K(ݦ�l�pf_D0�Ó`mk��~�+љ���J%*����?8���ܥ�x[���7[s��������B}])��͓n뤻�EsX��)�@������-��K>��3��\pƩ|c�%����
ֶ�%��c��vc��=��Z��⭄!��Δht�Q��bc�M`9�-3d�L}'L&_�K�IC�k��R�z�ݎ��J�6�r�����Ko�b-�v��H���ϛ֖0�W�.�������/��:��Iʏ���7�Ф�T�yfLS����G�{��rkYQ��7���r����T2�����(��??��?L�������Ӆ���i����/� �'��+8�����σq�$��@'H�)�氐�DA�j��z�Jr*�d��8�`���d�#�m�<�O ���-��g��Q�#;�ujaO"��b������u�������b�dt�<�dWL�%�LD������\��Nܑ͹��+D-����&�.nA	(D<4
t�z�G�ܱ]��D�sD7֛��|b�_U����&Ud	X�!�?§d!��?2����')?��I>��|°�����9t �.@� �T.�{������� �d<��~��*�f\ާ�|8�*}̅�a���U�����U�����
��em�?~���{��J�E���l�28��t!�ʦ���?�ɮ��S�����	�^=p��"=��[�T�~��%���;��y���"� Be�
��j栨M�Ԃ���B�E��?uLS�nz\rDvQ�T[|_v�.�C�z����囪��CBQᶄ��k�����5�o��n�\ң߫L�:w��� ��~�j�1��- M���},��b�ǻ�L�"��L��30{0Չ�E��̧"c(��Ѐ�-�) b�9�	��}V�#3�3(�Q�w�بA`;F\e�s<�*�:!u��C��Ub0����%<�K��
z�\��<�#��,[%ߨ�ЃȄ)X#F~] ��� ��ap$�a�x����1��0&�+𤾗L7�<	p����&���@�WQu�N�CE*R|��׫>�� �7�4��m�U��0Ƌ>rh2���;	�L�*�{ޙ���<����>��ki���^��&|%�[�lWmL�"i� �vT��#�I�^�t�~��ʖ~����I��V�;�d(C����9�*�*46���0�����O o���3H�A�m�kH��3��ܴ<{2N�iȌ�3X�� '\^�%�O�=,,��F�`WN�� |���Yia<"���x+N�ҭ7��X���<�<9����"��|��aS�̴8�0����?�`1�g��\���K�W���/
��ta'-Ҹzb&j�RJ����o+��?���1�8j���N���_P?!�=`�wIU-f��K���I=t����h*�/a�W�t�1����=�7��͸�R�ö��I�a��C;�p,S��/� e~	�C��Y`vy��0B+
�"G�m0g�^i#w�� ;f�H����\��+	�KB��V��]X۱���"Zy�o���Z��2'"�rP��g�Fu�:Cq�X|��dг�x{���ص��������/?R�yJ���)Ը�k "�/{䙨�QAh�B@Bh�f3z���$�J�I���b��e^���k�qK�ӽ���g�g�ܶ`��������v|��4�%q;q�\)�r�q�8�8�hP�va�Zм�}�+�+,��@�yA<��V����*]U]U]�g����Uu||=>������g�^�^so}Q�Am�a�/,�h���V�$e�}/�!��b����&�s��i%���)�BO�b;9�J�/���/Y^��KҬ�ʑ��Do��&������+�`�#���o<���:9�2[vl7�@�2��1��o��>��޾�+6����1�wf�s\�'��� 1�D���p���] ��m�-������~��/�zj^���H�0����R��E)�h�(CIU�#0�FE0M�(�����Zǡ߿�{�>0DC_/m�C@�Eϗ�^8�: '�<��k :;�s������z� o�:9�����N��[�+_����{�-/s�|��:7���	�u+}yS�]'���G�
�u�^��ڵ���K\��?9��s\2��E����@#A��	���H�3�GF��o�K�/�1�k�o���s9����ӟ�ǧ��Շ�
}� �;��_;�u��?Zp�Kެ��3v�����F�
�X�N��`p#k�B�N�5�;pL�P\ǣuE���z��ť
�z�_��g�������'_��':u2��?|�?=�wa�m�m��7�K[��߼}���:�_�C�}E�����_�Y���C�݇��>��j���;����[,K�u\�K�2�h�YI*���V�a8:�F��ne����-f����6l卭���ܹ)��勭)�&2�unY���cp~EZ�9�T�ӨتLŖ�����͖e��	q����2�nE���"�D�_ޚ�;=�R���jV�XM1Wqb�b[�wŽ����f�#�4T����sR��q�_��;E�RB�Z�0���H�9N�X�� ?�Z�<~~�X��Jb�����M2b��5N6h�e!*m��!a�JΘN=�o���!_�G�ү�)d>��B��YCKѱLR.��v4籘4�#}g��s­�7U�!��s���;"]��D�L���v8gQYYV.8��3�9�[�ȕ1^0d#���>9�:��
�W�PM�N��Y(wg��n4{}�t�e.�2G;��V�5b**o�#0��>��1=��5�2O��+�˖V�	uR�F9:nG�I�F(��=H	=]����a>|AJۣ?��7Žޤ�'I��q�.J�Y=��g�2iv��%�I*��}I*���:�4�JMp���^�IBi���	��侲#�����{�
.M(GSSFF��i^����f%Uj�#�k�RNI2	;�.I+WhT������i�"Y%�=��JyR��l��b�,n8���0i��������;�׶	��B�h�3��c�
r鶓��{���	j&3��!�hO`�:>��٠E��
2�S2X��ה��E�9���pӮ�HN���]*8Ej��Æ`����H�Y���=��"�yP.���
�3��I]*��r=3���	��x��D�/�(y�3;����'e�QLk��T��k�Κ���HJ�z|:�����^���\�� ��\��D��{��~Z�k����?�fc�%�6����qdʠ�P�"#�����֚Y��ХJ	�]���!*�����Y,VP�jα�T�<@�n��\&.7?`m�����.��4��*�
�4��3����n�D#��D�r�y��IӉ	Fe0�c�#7p'3d
��+%�2gxd��"x��r��'�%%ڨ��3��I���@˂:���F��`;�(��/�e�-�q������	@wܟ�^8|���V�o�|��]}���x�=6����B��Jk�o�v]v�2���[������^x5�^�q�~as�t�^ˋ�mם�s�n���]���Λп���\C?y��OV�����߇~��f�W��RYz�RY]=���(:�(C��2��ē�2Qohgl��<m��������~�9�%�p��{]~�\�:�Yt�皹�uT�6s�%u�o����f������w[� O��Zame,��p��H,M�s�O���%�1����걖("��&�:�A�Lj�D���٪�jj�vj�6�ŝѴ���h�4/wbI�z�b�:��Й%�D6~a��ʚ�,�9ƨ���4Gg�� ���&�"�x�!�˨5~�1:l�t���I��x��2�t�Ub�n�D���N�G�!%h��i�6����-�k��,t:EV�2���WA0^��N��h�!�X�X=x(s$�dl��Yz�:��%��� Z��`&���Ez��7/�4�'�k�,W�aA(tdq�N��tfh������{��� 2����O�؜.�2ב�k�6���ʜ�GD�2�Z�L��3��e²�۔9��^wwp�����`��[teuy����k%k,ǯf���9OF��hh�b���P�l:�V�Ce,��l�y]J�C�)zziks`ri}Tur�*���U_��5�V;\�h"_�K���1�:-��R(�K�̊4�����Ű�#ti�ԙ�xא��`�Ӊa5�!���\�N��2��P4�xR<c���s�ФEu���Ѭ��d��V
��̓�$`"�����'����v�S�h<o�ل)�$���3��Ti'aFVƻ��\���4�_]�'$�3$�C"J��ܳ�&9�IכjD<�J��[C�u��ʐLck�h����qgaL�u�`��������ckc����ڠ�m��r��O��P�Rl/4$�|�Y<e�:<5��p�ǳC�QB���������Z4��Ha����
�n��X��xb��9�,�u
X[�s
YHW�~$��}{�:�ڎl$'ᄌ�Z::ոh���PN1�Ơ0h3m�b`I\�M�^/��B���4KO: �P\G����a2f!�2N~Z��j��1�s�ʇ9̚)ժV�����u��.����_���j��-]�
��t��nt�����H�+����hN��2+6t��x�K�7������[@݃��E4�*G�˛%'���K��Ç��>|���5������Ep=��y���BTT-���C��,�g�.���<�o�{	u�4m����{�fǓ�`E���||eq�:RW;�)�ǃţ;�?�n��ުq6�� :o=n�c}_��xa�/�M����>|�����a�����={\��7Q��r�K������/���	>Z!<ڴ��;^ ?��m����><zߋ�Α�h�����n%w�n��-o�l^wߏ��ң�?:�"ٹi���h�V�i >���hy��̆�
Ļ���c��sP�n�G�7��:�o:ul�t�ؾ�D��$o8��������E�7��:�o:ul�7ul?�]8��>������?Lwm#m���>��a�O��{D�B�����z������l/��3�k���r���q��[������(A<��". ����tR����A��,
,�RIg�Ǹ��Ē�d��CDO=5ۉ��L�ۼ��s���Q�n��{H*�n�G��c�YIMg
S��m(�����=�:se~?��n��-��^r�K�����S�?����K���z�R��o��c`������D�����s�����/r�����	���e2�mP�'\�A_$A�8쨞8�e�'�fR]3L��qT3t�#e]��,kb�8]��R������di:7��C� �zb�=��,��kuC5ݸ�b�0�s��Y:^(&иi�͒]�v�J�QU��\a<Ks	�;:#6�"��>��1������;�Е�q��_%0#P/�?���������n(���x����d�x��O�;�U����G/�k���{��ad0���u�_�L��.<�h�'��5��{��$r��р�w����2e�i]�����������K�����?������8��]�O��To�`0:�'���w�����O0����k�v��w���z�����cW���=��X�{'��a���}O����t��>g�G��v?��$����|뿽������N��f{0�#��#g�?���ȃ��ur�;��������Nb�����#k,����|뿽�=��#��{���_�U ��^���9�����ٖ�lKA���d[��>������S��������|뿽�����{��� ���0�����`�?��~��&����m}6uz���������>�9��'��_;�^�F��õ(Y�U/}I�k
�1����(��dTG4�����[pL�)��0�k��^��=���#�Y�?��7� ���!�yG'�r�j3���AL"T<�K�$�r�ɤzEc4�3"�����v##��,Y)���/D�᪡N3Rl���I�����d�^Krֈ�#��xՎ��^�GQ�1R�j�\/i>>������>�� �������`�w��?����>���?�����纁~?�����������Ǩ���Ǳ\-��2r(M��0�J�%ǣXklT�k�/�ۙ��Qڝ�6���~��A�JG�c�ǰ8�"�ؤ?&�DD�S�B=�21�5���~+Y��:ڎ�p���P����b?�$��	~�M}O|���b�W���o��
��
��
��
�����O�}�^�?�8��"���.���������� �]5��8��I�s��b����N.�cbL5��jm�d�����h4���]I��J�}c~ś�֕����
���� {QP�_�i6u�J�[�u+��ʳG���掽#�9��v��@�B�7�χY���`0m�QE�5�4���bX�IO�Ke�*WI�5G�N�F]v��4吇��5O��`6����Vg�q�ۭ�Q[C�>i��o>ߦd�%fM�B�L�k���o��P��`����.��oO=�c6u����{+��7�Ͼj��:7UF�\��n�a�
k�1VX$���,:���X-Z'mz˹�SvM>W��ث��%y�#�|�=��pŢZ4j�OH����{����[���翜�x@��g�����8����#� ��/��Y�n�� I��8�����#y������I������a�#�,���w�a�&�X�a�� ����	��2w�!��	���<"��]����!������/�!����G��0�\��������_0�?�y D����W���0��?�����#�����������
������o���<�������c6�����?�	����l�g����?�������/�'�?������t��ʐR��_:��w�?!��	��?���\����<�@�O,�����?@��r��]�/��P����	Ԇ����[����������3`�A�������?�����V��f�Gc7�6�\��7�<h�I�����%��������p�ẻ
׃�k��?ՀP/�|���ٮ��{��i"v֔m�UQ�6�n��96��zH\/ʪ���2c��q֝9�`Ve�کΉE{��bӭ���k@�[ȿ��nE �T�-Ԣ{u���2S�T�[=�b:�,qӠ�;i���Y-S��H+��ۚ�)k����z1sA="����"c�@+A<b<�f�Oc��"��`��`A���C�
���[�������������C�����w�?@�G�����#����?hY*��n�G���/$�?4��"�?�������������`�wI(]�-�s�o���R ��s�?��c���q���^
'ű�B��(�rt���|�l̲��D�4��8�(��H�%v*���}���O	�ω���������t����o�����&��h���wV���疮�|\�u͢t��/M�ޜ��Ak<I�5��K�q�t{�h�m7�e-�Je�Uo���s����1�����"q�KuH��e-���	��{<N�E������4���2/�a�:)Ff�Uq�h�;���G���U�'$�����<����+8�-$�������?JC����[�����/ŧ	���<�J����lQ:VC�Niʨ.y4\h����z�j���۽�?������߱i�|�u��^0��P����3�RPg�����\\k�6��m!���n���f�y]��xt��,����]�A�a�ǁ�������+�{���������/����/���W��h�r@���_I�����_����Z�0��c'��z1�����u������?��z-x[PY&��L1�!�U���Vq����ꀂp9�E�e��I��U.\Ld)?�bo����\�QQ��"�V3L�FPg�I�ݵ��Bז��eu�yR������j7���y~]-n{���z~M+��~�ԣ�������_M�f*��&���l�zP=��x���H�`htA5�����׿bk��o��d�X�s�k!=��_���[/R��X&�s���F=rS+ԥ�u��6����y�L�n܏��������B�_f���f���m̂f}�xS�wn�п�`�h�Q����	��8@��g������_,���=������߻�_�(J��q ���/�����Z�$�|����\,����7�	R�A  �H��_	��`*3�XF�>��
�]��{��>�w}����2�W����b"�&���ӧN�9�V�ʉ�f{�(ڡ�z'Q�����-7�B��l��ߏ����y��C�|4�?�t�"/b�������jA�������E���<�/�.�)����H���Aׇy1Tb�giV��P�9%F����Q�0(�Cf
�@�?��ba�~��3�$V��`w��*�)s2ݏAg���q
Ď`�Sv6Ѣ�wW~�V�~&�|K+���Q�����<�?L�"�����q4��8 �_P��_����_�}K�~�����F��������'�WE^?s�9�����<H��p����>�����~hٯ�8��O���.��1��gi�~���c.����@J�?������aB��� S�%�� ��/����Wi ��C�<���K�)��_:�w�?���@���o�1��.�����̷���/B�������F����g4��L��J�j(�H�~��$s���ҟ�R�Y4���;�_t�8����Z���c��q�:���;9����99S㡰@#w\̉����<s��kl���m�*t��k��PQ����90ʩ;_���L�z��9�,j�K�]_x����W$e���l���M��G�"���2�X3��2�ؗf㬭��ݬڪf�Dȋ�n�fM撻3�7�U��r��nx�n���٥Vs�=fW#���'
3��N�.��)�չE�4��ʲ֎*?E����c��j�O�נX���~��D^��9Tƛv�%�W;)3�:�����C�55i�lˋG�mϭ�f���m���^dW���_TW�"���L��:)�J�T�-_�W��׳ih�/��!�mk�
}AD�a�ϻ����c���)_�v�Mʋy���Z ���h�7��a�/�'�(	��?��#����_�?�������`�A����������������p������U�:oG�|k.W�]�Wx���_V_����r�\�n����n���9N�d��Z?|bQ����wa�Nߦ�}��[<=F�>FZp���٭�u/��VF�h��6EQ�&;GCA}�S�M���Wi[լ��<ic-O��3ض��;���Å��ƌv���i-�i���1j�����s��&�$-��Iv�L;]qg+)��~_k9*oQO�Zϳn�����ǫ�PU�6���<���Tmm�����ٚB���e�\��u/
m�n�i�&:s�!�y����򲞊��DuL_�=�Ϛ�H�f��㈗�E�Ju��T$���f��O���􄦸]���t[ۚ)2��Q�C��z���+�q��]�ϯ������� ��迧� �P��n�G����7����}b` H�������a���ϸ��W�����Q��*���;�W]}s�?�gK9���X��ᭉ
u�� ���>�� ��@�� �O��6�מ6��P�A��,�t�Æ�ZR���4�U�0.�ϥɰ��X��ʰ�.����Xg�P�;��m�����t��T���M�-�O�~�z�' M�j\�U�����{���l���m�..JS[,�����>�%�R�G^i3���)bĬy!�v��FQی��2?\ސa���%�Gc�֗ldZ��`.���;Ԕ�/�X_eqm�)�D�?���� ��n_�_��n�G���/d�? p�����������k��@��c�?�8@��[F�,��#p�% ����$�?��{���, ���*:�� �CI�h9��(�@��"�Dy����1�����R�L�{?H��G��������F�v�ji����̗�HM���1�ȵ���qU3���mz��2���?�����ҥ�e���նD	�����
g���Pg�y�φ�=��lĢP����2�}:ZG�3�::��Q���C���P�����зT�����+D�?��(������j˾�$�?����+�_'��T����V�4S*���H�/:�K׺~g��򳚚�����2�z+�R�ە>�����|u0�x4�)��";�N̩f������u��ӓ��:;��96�F�5탱�,:3Sp���(�X�Y��-	��!�+�����w 	�/��*P��_P��_������Ѐe��w�g������=��~��o}�Zc;����7���-���x�?\�ղ_�����M��D�XL,�@�Gz�si��/�~X�ǥ��^}�	]gxjj��ܮgӰ�k��E����f�M�q�^.�����u��V"�������k[P��n��\�[���[�����_�
G���Zbִ�_�.T��n�@�Ej��$�ȵ��d���vY'�,S���ڙ����X T����t
��b8�3��Q��婝��q@�O��$�J�j-'Mu���єc6Jmmf�,Wye���6I�#�vܲoRA�y����
����A�?�Ƃ�_�a�+��q��w�G?�p���"�_x��p��x����
������e8�����]I.���W�b����0�濖��Ż�'��c�#^H��ϭ�H��e �_��?�x!
D�����X ���C�����A�}���/�����$�?����a�Q ��?���C�,��/0�����_������y�8��������g���!��@����P��X���.�o��v�������C�����?����b��((�˴4ES����F
BHy%�hY�#S�e$ı�TV"^�$��}H����?��?���x����vpX^����٤�R�<`U?n���݀����o=!z�����a�ʻ�T���|�'�Iڱm�q� B�����q�	��"$��|��dK�;y���p�y�(�[Eս���ւt�Єֺ۽g�uˬ�ƤwW�-��a�S\s��}��I�¤ݜ׃���j����>��m>ό�=�I�����o�S��}�?�������`�G<p�t��������0t
�OS{��������ӤC����4)������������g�����w:������@�9R��
aC�����2TD9��Q2��Ȝ��S�lJ�29(�
DF�(�S �C�������?C�2���7���e��^��8�Իd�>v�������ȁ��`)l��܁�d=y�Q;��̳�P-�f?�k��Fgݪs}}J�T�C�)�~��g|��^���6����Rd.oD��'��Q���o�S��������g����*��&�OSq��t
�O�{����A����|����cS��1�������������!�L1���t��������	��e�#R��1�����?1��N����G�C�����@����CP|�C|�C|�C|��q��=�?��8�����Z�m�cQ������I�(����x:)�ߟ)�#������()��@�~�����q�goE����e�]�����[�a����j�?��m������ο������V��Ȟ#�^U$�oԵ;�m�u�.A��b�G�Rי�x�������*\E�)�>_șw�aFe�#Ζ��-��L�Q���'v�{��Y?���|�e�j��O9��W,vǍ'6~�[��.b�iW&l����=MTS�\o9��eh,h�&��(ks��H�*d��:��R�[��r���q~p^񉹣T��z��[��`�����?`:	���>���������>~����(��o��$�?�'��� tZ��uh:���O4���������������������#�[?vk�~�����w���G��������?������^�����e~��w؆�4���Jk�&�[��h?��|�^�uv���:?�W�=�	�h����d̑w�CaU�����+�=�+��[�~D�V�{f�zB)����f2�n8g�MO%�\�����1!j���Dn�{�ߘV�z�B6{z�ӦA�I#�SN±��e�X�V(�1L�������4�?J���Ȓ�+y��kS�٪۫��2۸�G��4�f
b��]se�6�F����*[-�JW����8;^��\���8u��Ɍa]�����ju�)؇/�s��o�Z���z�αjN`�,[��ׯ��Y���nn�E/�U�<awj3�:�[̻P��ͦM��L]���eF�:k=��:�%5�.��J�g�j;C��v'�F�ɉ���0�����l���]s���%�$���MW3ּq�V��%,D����Y�K���H�k��g�J��a��L'a�Q{���<���7�kǵl{�G�������S���Y�������)ῢJTVVӔ"�JI���K��|^�$d�����,�2)1���$�)9#�S��DB2�F���)�����c��0�+��w�k��t�sV+YL62�c9��}�_-�l�<����b��N�J|t�;�S���L��0��q^����£�E�Mjc{v�j���iM�f��;[�M��~�E���R�ERKk%�3;��������J�0�����<��F<�{T:��?���G'����G�����r���!�������W�^�-���p�4�ZV�޸�f�E>ӟ�lA6���TNw�cy�O��2Ma�k���k's�_4�Kb�>9!T���<�3�L#;��j,�B�=_>WV��^w8�3�#��m�%�L�'�ӱ��V:���G��e1!���m��@���+��u<�������_���8��Ǎ��6�1�$�l����J���!�5�o|��?-����1n�gE��o��U�ta5z��_�e��=�l��͎C kk�g� A��@l۳{�  SU.y��T	�	��= l{�ZL�_e��5�JU�-��������b��^��Zќv��N����s��Բ�VPγ�Ƶ(l~����zk��|�5�Sm,��6n��Z�
����}y���/r~�C���iB�C�'�N߰a�I�l9�i-�(-\A�Q��}��9�Ur��M3�m:�_u��@�nO��9_49c|S��w5��M���N��m�"�d���dN��e�|4��9]��J�$��zw7`δYcun
�Iص��5�ʰ�;��ef��Շ9_[q*9\�z��;�=���'���x��W�?�e�]����������bm�������E��:8�ȅ� >@�U����24xQQ����K�.Dy/���������@;05�3p
P�M�R��m���h��nj(9x���_\���\ �Z�_T�;� q/�J �`�Eݼ[v[�����Ϻ(�؅�B�4,��0�Ѕ u[�A�[ߩ6AU.���aʖ�A�D���y�o�bla��oj�^�Q�*��G�}�v�������j?G�
܉� ʁ����(%C��C�u�ȶM��:@7����_8P{v W	 �(��;����".��I�Q�.�jc�!��6@5M ڶ���DT/�֡�xhxL[�W	eu}���P"}��D� �܁w�nC��M���K�,_�#"��������ã6��P6>7��/A]� >�F����-d�غ1�<0�%�,�@�ǭq����~{G�e|��bߥ�?�Hl^�۷�
%�۷��2�':jcKrQ^T>jۥhx�Uۚ��������'�BQ�_���%4։w�-�}���e�4}v��g(�Y��l�U�{女8wz;7ʸ�\硨It�Pۅ�-�ʳ�J�h��~�~�����d�Y���*� �Ucn�0�w"�&B��Q��dw6�D�XG�t �\K˚����3<���r>Eb��-�t/��؍,~�G�ĵ4����AT�`$����|nb��C�n*p>w����]������G�bhrmOvC�XU>o��KbG��l��!n�r��s=� Td�s�!�ؼG��H�;��E���p�"򕡆y�o���踯�#�=������~A�e�0t�}'���`��P�%�n�� ���2�Z6j�շo�gwӷo(G$&�N}<ν�.Em�ۑP<�Q��=ܢ�XT�@�n��GܼS���}�A�8�?��O,ߵ$O7���z[����d(���d���?��� �mBQp�*�'�C �ɲ]Pd�N��勥��+_}lD��]av�Rud���D�f	��Bpay��s9Òg � _Zx?!����ODӄƆ�e��[m3��D$�`�R ��Q��qG��un��:����t6X�C�U�d���T�����{M���� ��2Ɛ=��C�>54�O�hPѐPD"#���_F��`���\�eb��1β��ܬWI��ɽ�"���`W����`�=�%>|�)�/Vjo(|3���t�/�*�~���QM�3-�R:����N�TZ�dTY�*�dUJi)���ӊ�Jj>#2L�tF�ufD�`���[gY2�\�?�A������"���>�]�G1�_5��7�����y����XRyQʤEI�H&GfQ�h�Ȥ�E1�a�0K�29�%�),�PK���BJ̈5��@p��e�w��S�K���p��?>�-��˷�M�&��}����e����5���{2����oS�f� t�T����ak��f�&�ڕ%O{9[��l����+2��bn�o�ҭ�r�p�%䵬��kc9�dY��R<[�w[��Ud���Ws*��U��[D�L|˞!_�V��K��nR��;I:��ԐS�I�,=�]�����O�8����'ءh?�Ms�d�� �a�cK	��?��$��!n��>m!T���B��}�WD?�6y�y��@V� t�zp�/���,<�u� p��n�A�VhZ�J�w���2�L�8Kr)�I�3#�*�l�g�$.�I�w^x7�F�^hM$Գ��|=Znv{|�Q��nBo��T����6jt������:��7��Pj�=p�I����<v�P(�g�=�'�l��خp��\yRྒྷ�o��r���)��4��W��t>��R}��yGq�E�z����+U4��
S���.R8%��R?��L�y��g�</�I?�d��<�~X	n������"+��9_)�H$0m�c�h��>�lX<E�'=���Q��Q���wj��E͙Dc�h��J�!?��Z���V�υ��X�Yn&������O����?�B~E�q�'�������ÿ%%�LJ�3��6��3��ێ�m[�W��u��al��Ix��.�3�B����lH`Y���D�/����K�(�nٳm<�� ��u�������@V ��	�<�����m���������v�����,|��l��B��.裦>�s8k�E���>(�T췳�0�t��`7�.T�<�f8L�*�̸���6�[�pR#Pa<:���`#�H���%�	�lu;C�Nl�a��Fv3�P	'k��_�
MaEC����k{����wn�w_0���ٛ&�4��@6�h��!�jz+�;���������4����2�J���4����t��� �ʞ���Jk�ld��?3&<˾'8��0,�9�L��5c�&���7�+��bB���"�3������߃�����wU�����'P��:)�p \���jMY��-���
&�����K"qN��a��fn����ņ��џ��b|�q����O*����[F��5����l1�4T{�k���+�}��l�VZ+���fhT,^��%6����	<�J=�Mdࡘ��׸<w�������/�}Qu�IX�׾L�%�e��H�b�A����+�Q���+&�O�z��s��&��e!x�&��ߝ�nK[Z����|/@����vg���
g�v0Y>N7��,\GS�n�ɨ\S�X|��x��=���u�%-&���j�[ۥ�gD�iM����q}p�-≯ŴlAn��l;�R]�S�S��6����
�����H����^��h�ܹ�l���l�w�AF�R�5n�e�~��J����P�����V�zJ���d�~|K�]\���Yb��5�	}_��3!�O�P��ա��_��㟝���R#�����q�Ǔxh&:�z�B��x�|F�VA<P�Q0Pj���z@�/��=�֫���?�d��'�ј���ҝ��;-�c��ʎ���?���Yo�#���U�f�� q�h��F{���� б��:Wh�>{y.�����tih6Kl�]RhL��݌X���>�VֆTt�=��@�k��f,��=93v�/�<�W̮sk'2�;�_����_D=�r��� ���C�����z�ڼ����'}K$��C�<��24�D_��39#�ܢ�d;;z:m� R�`�)�[eU%����������:m�:(��f_uJt��ٖO��U#�}��*�]�!#��H�cqG<cQFY��j�9-��T�t�~�K@�#�?7�`0��`0��`0��`0O� ��� 0 