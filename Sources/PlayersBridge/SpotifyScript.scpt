FasdUAS 1.101.10   ��   ��    k             l     ��������  ��  ��        h     �� 	�� 0 spotifyscript SpotifyScript 	 k       
 
     j     �� 
�� 
pare  4     �� 
�� 
pcls  m       �    N S O b j e c t      l     ��������  ��  ��        i  	     I      �������� 0 	isrunning 	isRunning��  ��    l         k            l     ��  ��    N H AppleScript will automatically launch apps before sending Apple events;     �   �   A p p l e S c r i p t   w i l l   a u t o m a t i c a l l y   l a u n c h   a p p s   b e f o r e   s e n d i n g   A p p l e   e v e n t s ;     !   l     �� " #��   " N H if that is undesirable, check the app object's `running` property first    # � $ $ �   i f   t h a t   i s   u n d e s i r a b l e ,   c h e c k   t h e   a p p   o b j e c t ' s   ` r u n n i n g `   p r o p e r t y   f i r s t !  %�� % L      & & n      ' ( ' 1    ��
�� 
prun ( m      ) )v                                                                                      @ alis      macOS                          BD ����Spotify.app                                                    ����            ����  
 cu             Applications  /:Applications:Spotify.app/     S p o t i f y . a p p    m a c O S  Applications/Spotify.app  / ��  ��      () -> NSNumber (Bool)     � * * ,   ( )   - >   N S N u m b e r   ( B o o l )   + , + l     ��������  ��  ��   ,  - . - i    / 0 / I      �������� 0 	playpause 	playPause��  ��   0 O    
 1 2 1 I   	������
�� .spfyPlPsnull��� ��� null��  ��   2 m      3 3v                                                                                      @ alis      macOS                          BD ����Spotify.app                                                    ����            ����  
 cu             Applications  /:Applications:Spotify.app/     S p o t i f y . a p p    m a c O S  Applications/Spotify.app  / ��   .  4 5 4 l     ��������  ��  ��   5  6 7 6 i    8 9 8 I      �������� 0 playerstate playerState��  ��   9 l    J : ; < : O     J = > = k    I ? ?  @ A @ Z    F B C���� B 1    ��
�� 
prun C k    B D D  E F E r     G H G 1    ��
�� 
pPlS H o      ���� 0 currentstate currentState F  I J I l   �� K L��   K L F ASOC does not bridge AppleScript's 'type class' and 'constant' values    L � M M �   A S O C   d o e s   n o t   b r i d g e   A p p l e S c r i p t ' s   ' t y p e   c l a s s '   a n d   ' c o n s t a n t '   v a l u e s J  N O N r     P Q P m    ����  Q o      ���� 0 i   O  R�� R X    B S�� T S k   ) = U U  V W V Z  ) 7 X Y���� X =  ) . Z [ Z o   ) *���� 0 currentstate currentState [ n   * - \ ] \ 1   + -��
�� 
pcnt ] o   * +���� 0 stateenumref stateEnumRef Y L   1 3 ^ ^ o   1 2���� 0 i  ��  ��   W  _�� _ r   8 = ` a ` [   8 ; b c b o   8 9���� 0 i   c m   9 :����  a o      ���� 0 i  ��  �� 0 stateenumref stateEnumRef T J     d d  e f e m    ��
�� ePlSkPSS f  g h g m    ��
�� ePlSkPSP h  i�� i m    ��
�� ePlSkPSp��  ��  ��  ��   A  j�� j l  G I k l m k L   G I n n m   G H����   l  
 'unknown'    m � o o    ' u n k n o w n '��   > m      p pv                                                                                      @ alis      macOS                          BD ����Spotify.app                                                    ����            ����  
 cu             Applications  /:Applications:Spotify.app/     S p o t i f y . a p p    m a c O S  Applications/Spotify.app  / ��   ; #  () -> NSNumber (PlayerState)    < � q q :   ( )   - >   N S N u m b e r   ( P l a y e r S t a t e ) 7  r s r l     ��������  ��  ��   s  t u t i    v w v I      �������� 0 previoustrack previousTrack��  ��   w O    
 x y x I   	������
�� .spfyPrevnull��� ��� null��  ��   y m      z zv                                                                                      @ alis      macOS                          BD ����Spotify.app                                                    ����            ����  
 cu             Applications  /:Applications:Spotify.app/     S p o t i f y . a p p    m a c O S  Applications/Spotify.app  / ��   u  { | { l     ��������  ��  ��   |  } ~ } i     �  I      �������� 0 	nexttrack 	nextTrack��  ��   � O    
 � � � I   	������
�� .spfyNextnull��� ��� null��  ��   � m      � �v                                                                                      @ alis      macOS                          BD ����Spotify.app                                                    ����            ����  
 cu             Applications  /:Applications:Spotify.app/     S p o t i f y . a p p    m a c O S  Applications/Spotify.app  / ��   ~  � � � l     ��������  ��  ��   �  � � � i     � � � I      �������� 0 soundvolume soundVolume��  ��   � l    
 � � � � O     
 � � � l   	 � � � � L    	 � � 1    ��
�� 
pVol � 5 / ASOC will convert returned integer to NSNumber    � � � � ^   A S O C   w i l l   c o n v e r t   r e t u r n e d   i n t e g e r   t o   N S N u m b e r � m      � �v                                                                                      @ alis      macOS                          BD ����Spotify.app                                                    ����            ����  
 cu             Applications  /:Applications:Spotify.app/     S p o t i f y . a p p    m a c O S  Applications/Spotify.app  / ��   � $  () -> NSNumber (Int, 0...100)    � � � � <   ( )   - >   N S N u m b e r   ( I n t ,   0 . . . 1 0 0 ) �  � � � l     ��������  ��  ��   �  � � � i  ! $ � � � I      �� ����� "0 setsoundvolume_ setSoundVolume_ �  ��� � o      ���� 0 	newvolume 	newVolume��  ��   � l     � � � � k      � �  � � � l     �� � ���   � K E ASOC does not convert NSObject parameters to AS types automatically�    � � � � �   A S O C   d o e s   n o t   c o n v e r t   N S O b j e c t   p a r a m e t e r s   t o   A S   t y p e s   a u t o m a t i c a l l y & �  ��� � O      � � � k     � �  � � � l   �� � ���   � V P �so be sure to coerce NSNumber to native integer before using it in Apple event    � � � � �   & s o   b e   s u r e   t o   c o e r c e   N S N u m b e r   t o   n a t i v e   i n t e g e r   b e f o r e   u s i n g   i t   i n   A p p l e   e v e n t �  ��� � r     � � � c     � � � o    ���� 0 	newvolume 	newVolume � m    ��
�� 
long � 1    
��
�� 
pVol��   � m      � �v                                                                                      @ alis      macOS                          BD ����Spotify.app                                                    ����            ����  
 cu             Applications  /:Applications:Spotify.app/     S p o t i f y . a p p    m a c O S  Applications/Spotify.app  / ��  ��   �   (NSNumber) -> ()    � � � � "   ( N S N u m b e r )   - >   ( ) �  � � � l     ��������  ��  ��   �  � � � i  % ( � � � I      �������� 0 	trackinfo 	trackInfo��  ��   � O     d � � � k    c � �  � � � r     � � � n    	 � � � 1    	��
�� 
pDur � 1    ��
�� 
pTrk � o      ���� 0 dur   �  � � � r     � � � n     � � � 1    ��
�� 
pnam � 1    ��
�� 
pTrk � o      ���� 0 nam   �  � � � r     � � � n     � � � 1    ��
�� 
pArt � 1    ��
�� 
pTrk � o      ���� 0 tar   �  � � � r    # � � � n    ! � � � 1    !��
�� 
pAlA � 1    ��
�� 
pTrk � o      ���� 0 aar   �  � � � Z   $ 1 � ����� � =  $ ' � � � o   $ %���� 0 aar   � m   % & � � � � �   � r   * - � � � m   * +��
�� 
msng � o      ���� 0 aar  ��  ��   �  � � � r   2 9 � � � n   2 7 � � � 1   5 7��
�� 
pAlb � 1   2 5��
�� 
pTrk � o      ���� 0 alb   �  � � � Z   : G � ����� � =  : = � � � o   : ;���� 0 alb   � m   ; < � � � � �   � r   @ C � � � m   @ A��
�� 
msng � o      ���� 0 alb  ��  ��   �  � � � r   H O � � � n   H M � � � 1   K M�
� 
aUrl � 1   H K�~
�~ 
pTrk � o      �}�} 0 art   �  ��| � L   P c � � K   P b � � �{ � ��{ 0 trackduration trackDuration � o   Q R�z�z 0 dur   � �y � ��y 0 	trackname 	trackName � o   S T�x�x 0 nam   � �w � �w "0 trackartworkurl trackArtworkURL � o   U V�v�v 0 art    �u�u 0 trackartist trackArtist o   W X�t�t 0 tar   �s�s 0 albumartist albumArtist o   Y Z�r�r 0 aar   �q�p�q 0 
trackalbum 
trackAlbum o   ] ^�o�o 0 alb  �p  �|   � m     v                                                                                      @ alis      macOS                          BD ����Spotify.app                                                    ����            ����  
 cu             Applications  /:Applications:Spotify.app/     S p o t i f y . a p p    m a c O S  Applications/Spotify.app  / ��   � �n l     �m�l�k�m  �l  �k  �n    �j l     �i�h�g�i  �h  �g  �j       �f	
�f  	 �e�e 0 spotifyscript SpotifyScript
 �d 	�d 0 spotifyscript SpotifyScript  �c�b
�c misccura
�b 
pcls �  N S O b j e c t �a�`�a   	�_�^�]�\�[�Z�Y�X�W
�_ 
pare�^ 0 	isrunning 	isRunning�] 0 	playpause 	playPause�\ 0 playerstate playerState�[ 0 previoustrack previousTrack�Z 0 	nexttrack 	nextTrack�Y 0 soundvolume soundVolume�X "0 setsoundvolume_ setSoundVolume_�W 0 	trackinfo 	trackInfo�`   �V �U�T�S�V 0 	isrunning 	isRunning�U  �T      )�R
�R 
prun�S ��,E �Q 0�P�O�N�Q 0 	playpause 	playPause�P  �O      3�M
�M .spfyPlPsnull��� ��� null�N � *j U �L 9�K�J�I�L 0 playerstate playerState�K  �J   �H�G�F�H 0 currentstate currentState�G 0 i  �F 0 stateenumref stateEnumRef 
 p�E�D�C�B�A�@�?�>�=
�E 
prun
�D 
pPlS
�C ePlSkPSS
�B ePlSkPSP
�A ePlSkPSp
�@ 
kocl
�? 
cobj
�> .corecnte****       ****
�= 
pcnt�I K� G*�,E <*�,E�OkE�O ,���mv[��l kh ���,  �Y hO�kE�[OY��Y hOjU �< w�;�: �9�< 0 previoustrack previousTrack�;  �:       z�8
�8 .spfyPrevnull��� ��� null�9 � *j U �7 ��6�5!"�4�7 0 	nexttrack 	nextTrack�6  �5  !  "  ��3
�3 .spfyNextnull��� ��� null�4 � *j U �2 ��1�0#$�/�2 0 soundvolume soundVolume�1  �0  #  $  ��.
�. 
pVol�/ � *�,EU �- ��,�+%&�*�- "0 setsoundvolume_ setSoundVolume_�, �)'�) '  �(�( 0 	newvolume 	newVolume�+  % �'�' 0 	newvolume 	newVolume&  ��&�%
�& 
long
�% 
pVol�* � 	��&*�,FU �$ ��#�"()�!�$ 0 	trackinfo 	trackInfo�#  �"  ( � ������  0 dur  � 0 nam  � 0 tar  � 0 aar  � 0 alb  � 0 art  ) ����� ��� ���������
� 
pTrk
� 
pDur
� 
pnam
� 
pArt
� 
pAlA
� 
msng
� 
pAlb
� 
aUrl� 0 trackduration trackDuration� 0 	trackname 	trackName� "0 trackartworkurl trackArtworkURL� 0 trackartist trackArtist� 0 albumartist albumArtist� 0 
trackalbum 
trackAlbum� �! e� a*�,�,E�O*�,�,E�O*�,�,E�O*�,�,E�O��  �E�Y hO*�,�,E�O��  �E�Y hO*�,�,E�O������a �a Uascr  ��ޭ