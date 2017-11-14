CREATE TABLE `playertrack_adv` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `sid` int(11) unsigned NOT NULL DEFAULT '0',
  `Type` varchar(4) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'T',
  `Text` varchar(256) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Trans` varchar(256) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `HUD` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE `playertrack_analytics` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `playerid` int(11) NOT NULL DEFAULT '-1',
  `connect_time` int(11) NOT NULL DEFAULT '-1',
  `connect_date` varchar(32) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `serverid` int(11) NOT NULL DEFAULT '-1',
  `map` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'unknown',
  `duration` int(11) NOT NULL DEFAULT '-1',
  `ip` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'unknown',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE `playertrack_authgroup` (
  `pid` int(11) unsigned NOT NULL DEFAULT '0',
  `index` int(11) unsigned NOT NULL DEFAULT '0',
  `name` varchar(32) NOT NULL DEFAULT '未认证',
  `exp` int(11) unsigned NOT NULL DEFAULT '0',
  `date` int(11) unsigned NOT NULL DEFAULT '0',
  `expired` int(11) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`pid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


CREATE TABLE `playertrack_couples` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `source_id` int(11) unsigned NOT NULL DEFAULT '0',
  `target_id` int(11) unsigned NOT NULL DEFAULT '0',
  `date` int(11) unsigned NOT NULL DEFAULT '0',
  `exp` int(11) unsigned NOT NULL DEFAULT '0',
  `together` int(11) unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`Id`),
  UNIQUE KEY `P` (`source_id`,`target_id`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=utf8;


CREATE TABLE `playertrack_csclog` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `sid` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `uid` int(11) NOT NULL DEFAULT '-1',
  `steamid` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'STEAM_ID_INVALID',
  `name` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'unregister',
  `date` int(11) NOT NULL DEFAULT '0',
  `message` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE `playertrack_deathmodel` (
  `date` int(11) NOT NULL DEFAULT '0',
  `sid` tinyint(3) unsigned NOT NULL DEFAULT '0',
  `playerid` int(11) unsigned NOT NULL DEFAULT '0',
  `attackerid` int(11) unsigned NOT NULL DEFAULT '0',
  `headshot` bit(1) NOT NULL DEFAULT b'0',
  `weapon` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'weapon_unknown',
  `model` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'none',
  PRIMARY KEY (`sid`,`playerid`,`date`,`attackerid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE `playertrack_officalgroup` (
  `steamid` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`steamid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE `playertrack_player` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(32) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `steamid` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `onlines` int(11) unsigned NOT NULL DEFAULT '0',
  `firsttime` int(11) NOT NULL DEFAULT '-1',
  `lasttime` int(11) DEFAULT NULL,
  `number` int(11) unsigned NOT NULL DEFAULT '0',
  `signature` varchar(256) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '该玩家未设置签名！',
  `signnumber` int(11) unsigned NOT NULL DEFAULT '0',
  `signtime` int(11) unsigned NOT NULL DEFAULT '0',
  `active` smallint(4) unsigned DEFAULT '50',
  `daytime` smallint(6) unsigned DEFAULT '0',
  PRIMARY KEY (`steamid`),
  UNIQUE KEY `KEY_2` (`id`,`steamid`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE `playertrack_server` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `servername` varchar(64) DEFAULT NULL,
  `serverip` varchar(32) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=utf8;


CREATE TABLE `playertrack_webinterface` (
  `playerid` int(11) unsigned NOT NULL DEFAULT '0',
  `show` bit(1) NOT NULL DEFAULT b'0',
  `width` smallint(6) NOT NULL DEFAULT '1268',
  `height` smallint(6) unsigned NOT NULL DEFAULT '640',
  `url` varchar(256) NOT NULL DEFAULT 'https://csgogamers.com/',
  PRIMARY KEY (`playerid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


CREATE TABLE `playertrack_variables` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `type` varchar(32) NOT NULL DEFAULT 'var',
  `key` varchar(32) NOT NULL DEFAULT 'INVALID_KEY',
  `var` varchar(128) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `k` (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;