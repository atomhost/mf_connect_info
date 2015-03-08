<?php
if(!isset($_GET['ip']) OR !isset($_GET['id'])){
	include('include/404.php');
	return;
}

//global $arGeoCodes;
//берем данные ИП и СТИМИД из гет запроса
include('include/country_name.php');
include('include/conf.php');

$ip = $_GET['ip'];
$id = $_GET['id'];

/*заполняем массив ответа пустыми значениями*/
$user_info = array();
$user_info['id64'] = '-';
$user_info['status_steam'] = '-';
$user_info['real_name'] = '-';
$user_info['country'] = '-';
$user_info['district'] = '-';
$user_info['region'] = '-';
$user_info['city'] = '-';
$user_info['provider'] = '-';
$user_info['vac_banned'] = '-';
$user_info['vac_ban_count'] = '-';

//коннектимся к БД
$db = mysql_connect($db_host, $db_user, $db_password);
mysql_select_db($db_base,$db); 


function get_input_type($data){
	$data = strtolower(trim($data));
	if($data!=''){
		if (strlen($data)>80)
			return 0;
		
		if (substr($data,0,7)=='steam_0') {
			$tmp=explode(':',$data);
			if ((count($tmp)==3) && is_numeric($tmp[1]) && is_numeric($tmp[2])){
				return bcadd((($tmp[2]*2)+$tmp[1]),'76561197960265728');
			}
			else 
				return 0;
		}else if (is_numeric($data))
			return $data;
	}
		else
			return 0;
}

//считаем стимид64
$steamid64=get_input_type($id);
if($steamid64>0){
	//*
	$user_info['id64'] = $steamid64;
	$result = mysql_query("SELECT * FROM ci_data WHERE id64=".$steamid64, $db);
	$db_data = mysql_fetch_array($result);
	
	if(count($db_data)>1){
		if($db_upadete_hour>0){
			$c_date = time();
			if(($db_data['last_update'] + ($db_upadete_hour * 3600))< $c_date ){
				//обновляем данные
				LoadSteamData($steamid64,$steam_key, true);
				$result = mysql_query("SELECT * FROM ci_data WHERE id64=".$steamid64, $db);
				$db_data = mysql_fetch_array($result);
			}

				
		}
	}
	else{
		LoadSteamData($steamid64,$steam_key, false);
		$result = mysql_query("SELECT * FROM ci_data WHERE id64=".$steamid64, $db);
		$db_data = mysql_fetch_array($result);
	}
	//*
	$user_info['status_steam'] = $db_data['steam'];
	$user_info['real_name'] = $db_data['name'];
	$user_info['provider'] = $db_data['provider'];
	$user_info['vac_banned'] = $db_data['vac_banned'];
	$user_info['vac_ban_count'] = $db_data['vac_ban_count'];

}

function LoadSteamData($id64, $key, $update){
	$t_status = $vac_banned = $vac_banneds_count = 0;
	$t_name = $t_provider ='-';
	$urljson = file_get_contents("http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key=".$key."&steamids=".$id64);
	$data_steam = (array) json_decode($urljson)->response->players[0];
		
	if(count($data_steam['lastlogoff'])>0){
		$t_status = 1;
	
		if(count($data_steam['realname'])>0)
			$t_name = $data_steam['realname'];
		
		$urljson_ban = file_get_contents("http://api.steampowered.com/ISteamUser/GetPlayerBans/v1/?key=".$key."&steamids=".$id64);
		$data_ban = (array) json_decode($urljson_ban)->players[0];
		$vac_ban_count = $data_ban['NumberOfVACBans'];
		if($data_ban['VACBanned'])
			$vac_banned = 1;
		else
			$vac_banned = 0;
	}else {
		$t_status = 0;
	}
	$t_provider = "unknown";
	$time = time();
	if($update)
		mysql_query ("UPDATE ci_data SET name='$t_name', provider='$t_provider', vac_banned=$vac_banned,vac_ban_count=$vac_ban_count, last_update=$time WHERE id64=$id64");
	else
		mysql_query ("INSERT INTO ci_data (id64, steam, name, provider, vac_banned, vac_ban_count, last_update) VALUES ($id64, $t_status, '$t_name', '$t_provider', $vac_banned, $vac_ban_count, $time)");
}


	
//парсим базу геоданных
require_once("include/ipgeobase.php");
$gb = new IPGeoBase();
$data = $gb->getRecord($ip);

//Расшифровываем код страны
$data['cc'] = !empty($data['cc']) ? $arGeoCodes[$data['cc']] : '';

if(count($data) > 1){
	$user_info['country'] = $data['cc'];
	if(count($data) < 3)
		$user_info['city'] = '-';
	else
		$user_info['city'] = win2utf($data['city']);

	if(count($data) < 4)
		$user_info['region'] = '-';
	else
		$user_info['region'] = win2utf($data['region']);

	if(count($data) < 5)
		$user_info['district'] = '-';
	else
		$user_info['district'] = win2utf($data['district']);
	
}

//выводим инфу с разделителем ;
echo ';',$user_info['id64'],';', $user_info['status_steam'],';', $user_info['real_name'],';', $user_info['country'] ,';', $user_info['district'],';', $user_info['region'],';', $user_info['city'],';', $user_info['provider'],';', $user_info['vac_banned'],';', $user_info['vac_ban_count'];

//Функция перекодировки windows-1251 -> utf-8 (обновляемые файлы текстовой БД идут в кодировке windows-1251)
function win2utf($str){
    static $table = array("\xA8" => "\xD0\x81","\xB8" => "\xD1\x91","\xA1" => "\xD0\x8E","\xA2" => "\xD1\x9E","\xAA" => "\xD0\x84","\xAF" => "\xD0\x87","\xB2" => "\xD0\x86","\xB3" => "\xD1\x96","\xBA" => "\xD1\x94",
    "\xBF" => "\xD1\x97","\x8C" => "\xD3\x90","\x8D" => "\xD3\x96","\x8E" => "\xD2\xAA","\x8F" => "\xD3\xB2","\x9C" => "\xD3\x91","\x9D" => "\xD3\x97","\x9E" => "\xD2\xAB","\x9F" => "\xD3\xB3", ); 
	return preg_replace('#[\x80-\xFF]#se',' "$0" >= "\xF0" ? "\xD1".chr(ord("$0")-0x70) : ("$0" >= "\xC0" ? "\xD0".chr(ord("$0")-0x30) : (isset($table["$0"]) ? $table["$0"] : ""))',$str);
}
?>