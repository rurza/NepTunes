FasdUAS 1.101.10   ��   ��    k             l     ��������  ��  ��        l     ��������  ��  ��     	 
 	 h     �� �� 0 musicscript MusicScript  k             j     �� 
�� 
pare  4     �� 
�� 
pcls  m       �    N S O b j e c t      l     ��������  ��  ��        i  	     I      �������� 0 	isrunning 	isRunning��  ��    l         k            l     ��   ��    N H AppleScript will automatically launch apps before sending Apple events;      � ! ! �   A p p l e S c r i p t   w i l l   a u t o m a t i c a l l y   l a u n c h   a p p s   b e f o r e   s e n d i n g   A p p l e   e v e n t s ;   " # " l     �� $ %��   $ N H if that is undesirable, check the app object's `running` property first    % � & & �   i f   t h a t   i s   u n d e s i r a b l e ,   c h e c k   t h e   a p p   o b j e c t ' s   ` r u n n i n g `   p r o p e r t y   f i r s t #  '�� ' L      ( ( n      ) * ) 1    ��
�� 
prun * m      + +|                                                                                      @ alis      macOS                          BD ����	Music.app                                                      ����            ����  
 cu             Applications   /:System:Applications:Music.app/   	 M u s i c . a p p    m a c O S  System/Applications/Music.app   / ��  ��      () -> NSNumber (Bool)     � , , ,   ( )   - >   N S N u m b e r   ( B o o l )   - . - l     ��������  ��  ��   .  / 0 / i    1 2 1 I      �������� 0 	playpause 	playPause��  ��   2 O    
 3 4 3 I   	������
�� .hookPlPsnull��� ��� null��  ��   4 m      5 5|                                                                                      @ alis      macOS                          BD ����	Music.app                                                      ����            ����  
 cu             Applications   /:System:Applications:Music.app/   	 M u s i c . a p p    m a c O S  System/Applications/Music.app   / ��   0  6 7 6 l     ��������  ��  ��   7  8 9 8 i    : ; : I      �������� 0 playerstate playerState��  ��   ; l    L < = > < O     L ? @ ? k    K A A  B C B Z    H D E���� D 1    ��
�� 
prun E k    D F F  G H G r     I J I 1    ��
�� 
pPlS J o      ���� 0 currentstate currentState H  K L K l   �� M N��   M L F ASOC does not bridge AppleScript's 'type class' and 'constant' values    N � O O �   A S O C   d o e s   n o t   b r i d g e   A p p l e S c r i p t ' s   ' t y p e   c l a s s '   a n d   ' c o n s t a n t '   v a l u e s L  P Q P r     R S R m    ����  S o      ���� 0 i   Q  T�� T X    D U�� V U k   + ? W W  X Y X Z  + 9 Z [���� Z =  + 0 \ ] \ o   + ,���� 0 currentstate currentState ] n   , / ^ _ ^ 1   - /��
�� 
pcnt _ o   , -���� 0 stateenumref stateEnumRef [ L   3 5 ` ` o   3 4���� 0 i  ��  ��   Y  a�� a r   : ? b c b [   : = d e d o   : ;���� 0 i   e m   ; <����  c o      ���� 0 i  ��  �� 0 stateenumref stateEnumRef V J     f f  g h g m    ��
�� ePlSkPSS h  i j i m    ��
�� ePlSkPSP j  k l k m    ��
�� ePlSkPSp l  m n m m    ��
�� ePlSkPSF n  o�� o m    ��
�� ePlSkPSR��  ��  ��  ��   C  p�� p l  I K q r s q L   I K t t m   I J����   r  
 'unknown'    s � u u    ' u n k n o w n '��   @ m      v v|                                                                                      @ alis      macOS                          BD ����	Music.app                                                      ����            ����  
 cu             Applications   /:System:Applications:Music.app/   	 M u s i c . a p p    m a c O S  System/Applications/Music.app   / ��   = #  () -> NSNumber (PlayerState)    > � w w :   ( )   - >   N S N u m b e r   ( P l a y e r S t a t e ) 9  x y x l     ��������  ��  ��   y  z { z i    | } | I      �������� 0 	backtrack 	backTrack��  ��   } O    
 ~  ~ I   	������
�� .hookBacknull��� ��� null��  ��    m      � �|                                                                                      @ alis      macOS                          BD ����	Music.app                                                      ����            ����  
 cu             Applications   /:System:Applications:Music.app/   	 M u s i c . a p p    m a c O S  System/Applications/Music.app   / ��   {  � � � l     ��������  ��  ��   �  � � � i    � � � I      �������� 0 	nexttrack 	nextTrack��  ��   � O    
 � � � I   	������
�� .hookNextnull��� ��� null��  ��   � m      � �|                                                                                      @ alis      macOS                          BD ����	Music.app                                                      ����            ����  
 cu             Applications   /:System:Applications:Music.app/   	 M u s i c . a p p    m a c O S  System/Applications/Music.app   / ��   �  � � � l     ��������  ��  ��   �  � � � i     � � � I      �������� 0 soundvolume soundVolume��  ��   � l    
 � � � � O     
 � � � l   	 � � � � L    	 � � 1    ��
�� 
pVol � 5 / ASOC will convert returned integer to NSNumber    � � � � ^   A S O C   w i l l   c o n v e r t   r e t u r n e d   i n t e g e r   t o   N S N u m b e r � m      � �|                                                                                      @ alis      macOS                          BD ����	Music.app                                                      ����            ����  
 cu             Applications   /:System:Applications:Music.app/   	 M u s i c . a p p    m a c O S  System/Applications/Music.app   / ��   � $  () -> NSNumber (Int, 0...100)    � � � � <   ( )   - >   N S N u m b e r   ( I n t ,   0 . . . 1 0 0 ) �  � � � l     ��������  ��  ��   �  � � � i  ! $ � � � I      �� ����� "0 setsoundvolume_ setSoundVolume_ �  ��� � o      ���� 0 	newvolume 	newVolume��  ��   � l     � � � � k      � �  � � � l     �� � ���   � K E ASOC does not convert NSObject parameters to AS types automatically�    � � � � �   A S O C   d o e s   n o t   c o n v e r t   N S O b j e c t   p a r a m e t e r s   t o   A S   t y p e s   a u t o m a t i c a l l y & �  ��� � O      � � � k     � �  � � � l   �� � ���   � V P �so be sure to coerce NSNumber to native integer before using it in Apple event    � � � � �   & s o   b e   s u r e   t o   c o e r c e   N S N u m b e r   t o   n a t i v e   i n t e g e r   b e f o r e   u s i n g   i t   i n   A p p l e   e v e n t �  ��� � r     � � � c     � � � o    ���� 0 	newvolume 	newVolume � m    ��
�� 
long � 1    
��
�� 
pVol��   � m      � �|                                                                                      @ alis      macOS                          BD ����	Music.app                                                      ����            ����  
 cu             Applications   /:System:Applications:Music.app/   	 M u s i c . a p p    m a c O S  System/Applications/Music.app   / ��  ��   �   (NSNumber) -> ()    � � � � "   ( N S N u m b e r )   - >   ( ) �  � � � l     ��������  ��  ��   �  � � � i  % ( � � � I      �������� 0 	trackinfo 	trackInfo��  ��   � O     � � � � Z    � � ����� � 1    ��
�� 
prun � k    � � �  � � � r     � � � n     � � � 1    ��
�� 
pDur � 1    ��
�� 
pTrk � o      ���� 0 dur   �  � � � r     � � � n     � � � 1    ��
�� 
pnam � 1    ��
�� 
pTrk � o      ���� 0 nam   �  � � � r    " � � � n      � � � 1     ��
�� 
pArt � 1    ��
�� 
pTrk � o      ���� 0 tar   �  � � � r   # * � � � n   # ( � � � 1   & (��
�� 
pAlA � 1   # &��
�� 
pTrk � o      ���� 0 aar   �  � � � Z   + 8 � ����� � =  + . � � � o   + ,���� 0 aar   � m   , - � � � � �   � r   1 4 � � � m   1 2��
�� 
msng � o      ���� 0 aar  ��  ��   �  � � � r   9 @ � � � n   9 > � � � 1   < >�
� 
pAlb � 1   9 <�~
�~ 
pTrk � o      �}�} 0 alb   �  � � � Z   A N � ��|�{ � =  A D � � � o   A B�z�z 0 alb   � m   B C � � � � �   � r   G J � � � m   G H�y
�y 
msng � o      �x�x 0 alb  �|  �{   �  � � � Q   O i � � � � r   R ^ �  � n   R \ 1   Z \�w
�w 
pRaw n   R Z 4   W Z�v
�v 
cArt m   X Y�u�u  n   R W 2  U W�t
�t 
cArt 1   R U�s
�s 
pTrk  o      �r�r 0 art   � R      �q�p�o
�q .ascrerr ****      � ****�p  �o   � r   f i	 m   f g�n
�n 
msng	 o      �m�m 0 art   � 
�l
 L   j � K   j � �k�k 0 trackduration trackDuration o   k l�j�j 0 dur   �i�i 0 	trackname 	trackName o   o p�h�h 0 nam   �g�g $0 trackartworkdata trackArtworkData o   s t�f�f 0 art   �e�e 0 trackartist trackArtist o   w x�d�d 0 tar   �c�c 0 albumartist albumArtist o   { |�b�b 0 aar   �a�`�a 0 
trackalbum 
trackAlbum o    ��_�_ 0 alb  �`  �l  ��  ��   � m     |                                                                                      @ alis      macOS                          BD ����	Music.app                                                      ����            ����  
 cu             Applications   /:System:Applications:Music.app/   	 M u s i c . a p p    m a c O S  System/Applications/Music.app   / ��   �  l     �^�]�\�^  �]  �\    l     �[�Z�Y�[  �Z  �Y    i  ) ,  I      �X�W�V�X 0 
trackloved 
trackLoved�W  �V    O     !"! L    ## n    
$%$ 1    	�U
�U 
pLov% 1    �T
�T 
pTrk" m     &&|                                                                                      @ alis      macOS                          BD ����	Music.app                                                      ����            ����  
 cu             Applications   /:System:Applications:Music.app/   	 M u s i c . a p p    m a c O S  System/Applications/Music.app   / ��   '(' l     �S�R�Q�S  �R  �Q  ( )�P) l     �O�N�M�O  �N  �M  �P   
 *�L* l     �K�J�I�K  �J  �I  �L       �H+,�H  + �G�G 0 musicscript MusicScript, �F -.�F 0 musicscript MusicScript- // �E�D0
�E misccura
�D 
pcls0 �11  N S O b j e c t. �C2�B3456789:;�C  2 
�A�@�?�>�=�<�;�:�9�8
�A 
pare�@ 0 	isrunning 	isRunning�? 0 	playpause 	playPause�> 0 playerstate playerState�= 0 	backtrack 	backTrack�< 0 	nexttrack 	nextTrack�; 0 soundvolume soundVolume�: "0 setsoundvolume_ setSoundVolume_�9 0 	trackinfo 	trackInfo�8 0 
trackloved 
trackLoved�B  3 �7 �6�5<=�4�7 0 	isrunning 	isRunning�6  �5  <  =  +�3
�3 
prun�4 ��,E4 �2 2�1�0>?�/�2 0 	playpause 	playPause�1  �0  >  ?  5�.
�. .hookPlPsnull��� ��� null�/ � *j U5 �- ;�,�+@A�*�- 0 playerstate playerState�,  �+  @ �)�(�'�) 0 currentstate currentState�( 0 i  �' 0 stateenumref stateEnumRefA  v�&�%�$�#�"�!� �����
�& 
prun
�% 
pPlS
�$ ePlSkPSS
�# ePlSkPSP
�" ePlSkPSp
�! ePlSkPSF
�  ePlSkPSR� 
� 
kocl
� 
cobj
� .corecnte****       ****
� 
pcnt�* M� I*�,E >*�,E�OkE�O .������v[��l kh ���,  �Y hO�kE�[OY��Y hOjU6 � }��BC�� 0 	backtrack 	backTrack�  �  B  C  ��
� .hookBacknull��� ��� null� � *j U7 � ���DE�� 0 	nexttrack 	nextTrack�  �  D  E  ��
� .hookNextnull��� ��� null� � *j U8 � ���FG�� 0 soundvolume soundVolume�  �  F  G  ��
� 
pVol� � *�,EU9 � ��
�	HI�� "0 setsoundvolume_ setSoundVolume_�
 �J� J  �� 0 	newvolume 	newVolume�	  H �� 0 	newvolume 	newVolumeI  ���
� 
long
� 
pVol� � 	��&*�,FU: � ��� KL��� 0 	trackinfo 	trackInfo�  �   K �������������� 0 dur  �� 0 nam  �� 0 tar  �� 0 aar  �� 0 alb  �� 0 art  L ������������ ����� �����������������������
�� 
prun
�� 
pTrk
�� 
pDur
�� 
pnam
�� 
pArt
�� 
pAlA
�� 
msng
�� 
pAlb
�� 
cArt
�� 
pRaw��  ��  �� 0 trackduration trackDuration�� 0 	trackname 	trackName�� $0 trackartworkdata trackArtworkData�� 0 trackartist trackArtist�� 0 albumartist albumArtist�� 0 
trackalbum 
trackAlbum�� �� �� �*�,E *�,�,E�O*�,�,E�O*�,�,E�O*�,�,E�O��  �E�Y hO*�,�,E�O��  �E�Y hO *�,�-�k/�,E�W 
X  �E�O�a �a �a �a �a �a Y hU; �� ����MN���� 0 
trackloved 
trackLoved��  ��  M  N &����
�� 
pTrk
�� 
pLov�� � 	*�,�,EUascr  ��ޭ