VyHub.Dashboard = VyHub.Dashboard or {}

VyHub.Dashboard.ui = VyHub.Dashboard.ui or nil

VyHub.Dashboard.html_ready = false


local dashboard_html = nil

function VyHub.Dashboard:create_ui()
	VyHub.Dashboard.html_ready = false

	local xsize = ScrW() - ScrW()/4
	local ysize = ScrH() - ScrH()/4
	local xpos  = ScrW()/2 - xsize/2
	local ypos  = ScrH()/2 - ysize/2
	local title = "VyHub Server-Dashboard"

	VyHub.Dashboard.ui = vgui.Create("DFrame")
	VyHub.Dashboard.ui:SetSize(xsize, ysize)
	VyHub.Dashboard.ui:SetPos(xpos, ypos)
	VyHub.Dashboard.ui:SetDraggable(true)
	VyHub.Dashboard.ui:SetTitle(title)
	function VyHub.Dashboard.ui.Paint(self, w, h)
		draw.RoundedBox(0, 0, 0, w, 24, Color(94, 0, 0, 255))
	end

	VyHub.Dashboard.ui_html = vgui.Create("DHTML", VyHub.Dashboard.ui)
	VyHub.Dashboard.ui_html:SetSize(xsize, ysize - 24)
	VyHub.Dashboard.ui_html:SetPos(0, 24)
	VyHub.Dashboard.ui_html:SetHTML(dashboard_html)

	function VyHub.Dashboard.ui_html:OnDocumentReady()
		VyHub.Dashboard.html_ready = true
	end

	VyHub.Dashboard.ui_html:AddFunction("vyhub", "warning_toggle", function (warning_id)
		LocalPlayer():ConCommand(f("vh_warning_toggle %s", warning_id))
	end)
	VyHub.Dashboard.ui_html:AddFunction("vyhub", "warning_delete", function (warning_id)
		LocalPlayer():ConCommand(f("vh_warning_delete %s", warning_id))
	end)
	VyHub.Dashboard.ui_html:AddFunction("vyhub", "ban_set_status", function (ban_id, status)
		LocalPlayer():ConCommand(f("vh_ban_set_status %s %s", ban_id, status))
	end)
	VyHub.Dashboard.ui_html:AddFunction("vyhub", "warning_create", function (steamid, reason)
		LocalPlayer():ConCommand(f("vh_warn %s %s", steamid, reason))
	end)
	VyHub.Dashboard.ui_html:AddFunction("vyhub", "ban_create", function (steamid, minutes, reason)
		LocalPlayer():ConCommand(f('vh_ban %s %s "%s"', steamid, minutes, reason))
	end)
end


dashboard_html = [[
    <html>
		<head>
			<meta charset="utf-8">
    		<meta name="viewport" content="width=device-width, initial-scale=1">

			<!-- Botstrap CSS -->
			<!-- <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.4.1/css/bootstrap.min.css"> -->
			<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootswatch@3.4.1/darkly/bootstrap.min.css" integrity="sha384-nNK9n28pDUDDgIiIqZ/MiyO3F4/9vsMtReZK39klb/MtkZI3/LtjSjlmyVPS3KdN" crossorigin="anonymous">	
			<!-- Vertical Tabs CSS -->
			<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-vertical-tabs@1.2.2/bootstrap.vertical-tabs.min.css">		
			<!-- FA -->
			<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.2.0/css/solid.min.css" integrity="sha512-uj2QCZdpo8PSbRGL/g5mXek6HM/APd7k/B5Hx/rkVFPNOxAQMXD+t+bG4Zv8OAdUpydZTU3UHmyjjiHv2Ww0PA==" crossorigin="anonymous" referrerpolicy="no-referrer" />
			<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.2.0/css/fontawesome.min.css" integrity="sha512-RvQxwf+3zJuNwl4e0sZjQeX7kUa3o82bDETpgVCH2RiwYSZVDdFJ7N/woNigN/ldyOOoKw8584jM4plQdt8bhA==" crossorigin="anonymous" referrerpolicy="no-referrer" />

			<style>
				::selection {
					background: #b5b5b5; /* WebKit/Blink Browsers */
				}

				body{
					overflow-x: hidden;
				}

				.vh-input {
					background-color: #303030; 
					color: white; 
					height: 30px;
				}
			</style>
		</head>
        <body>	
			<script src="https://ajax.googleapis.com/ajax/libs/jquery/2.2.4/jquery.min.js"></script>
			<script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js" integrity="sha384-0mSbJDEHialfmuBBQP6A4Qrprq5OVfW37PRR3j5ELqxss1yVqOtnepnHVP9aJ7xS" crossorigin="anonymous"></script>
			<script src="https://cdnjs.cloudflare.com/ajax/libs/moment.js/2.29.4/moment.min.js" integrity="sha512-CryKbMe7sjSCDPl18jtJI5DR5jtkUWxPXWaLCst6QjH8wxDexfRJic2WRmRXmstr2Y8SxDDWuBO6CQC6IE4KTA==" crossorigin="anonymous" referrerpolicy="no-referrer"></script>

			<div class="row" style="margin: 10px">
				<div class="col-xs-3">
					<div class="input-group">
						<div style="height: 20px;" class="input-group-addon"><i class="fa-solid fa-search fa-xs"></i></div>
						<input id="user_search" type="text" class="form-control vh-input" onclick="$('#user_search').val(''); generate_user_list();" onkeyup="generate_user_list()" >
					</div>
					<hr>
					<ul class="nav nav-tabs tabs-left" id="user_list">

					</ul>
				</div>
				<div class="col-xs-9">
					<div id="user_content_empty">
						Please select an user.
					</div>
					<div class="tab-content" id="user_content" style="display: none;">
						<h3 style="margin: 10px 0px 0px 0;">
							<span class="label label-default" style="background-color: #5E0000">
								<i class="fa-solid fa-user"></i> &nbsp;<span id="user_content_name"></span>
							</span>
							<span id="user_memberships" class="pull-right">
							</span>
						</h3>
						<h5 style="margin: 12px 0px 20px 0;">
							<span class="label label-default">
								<i class="fa-solid fa-user"></i> &nbsp;<span id="user_content_username"></span>
							</span>
						</h5>

						<hr/>

						<h4><span class="label label-default"><i class="fa-solid fa-triangle-exclamation"></i> &nbsp;Warnings</span></h3>
						<table class="table table-condensed table-hover">
							<tr>
								<th width="10px"></th>
								<th>Reason</th>
								<th>Admin</th>
								<th>Date</th>
								<th class="text-right">Actions</th>
							</tr>

							<tbody id="user_content_warnings">
							</tbody>
						</table>

						<div>
							<span class="label label-success">Active</span>
							<span class="label label-warning">Inactive</span>
							<span class="label label-default">Disabled</span>
						</div>

						<br/>

						<div class="row">
							<div class="col-xs-10">
								<input id="user_warn" type="text" class="form-control vh-input" onclick="$('#user_warn').val('');" placeholder="Reason" />
							</div>
							<div class="col-xs-2" style="padding-left: 0;">
								<button style="height: 30px;" onclick="create_warning()" class="btn btn-warning btn-xs btn-block"><i class="fa-solid fa-triangle-exclamation"></i> &nbsp; Warn</button>
							</div>
						</div>

						<hr />
						
						<h4><span class="label label-default"><i class="fa-solid fa-gavel"></i> &nbsp;Bans</span></h3>
						<table class="table table-condensed table-hover">
							<tr>
								<th width="10px"></th>
								<th>Reason</th>
								<th>Admin</th>
								<th>Date</th>
								<th>Minutes</th>
								<th class="text-right">Actions</th>
							</tr>

							<tbody id="user_content_bans">
							</tbody>
						</table>

						<div>
							<span class="label label-success">Active</span>
							<span class="label label-info">Active (Global)</span>
							<span class="label label-warning">Unbanned</span>
							<span class="label label-danger">Inactive</span>
						</div>

						<br/>

						<div class="row">
							<div class="col-xs-8">
								<input id="user_ban_reason" type="text" class="form-control vh-input" onclick="$('#user_ban_reason').val('');" placeholder="Reason" />
							</div>
							<div class="col-xs-2" style="padding-left: 0;">
								<input id="user_ban_minutes" type="text" class="form-control vh-input" onclick="$('#user_ban_minutes').val('');" placeholder="Minutes" />
							</div>
							<div class="col-xs-2" style="padding-left: 0;">
								<button style="height: 30px;" onclick="create_ban()" class="btn btn-danger btn-xs btn-block"><i class="fa-solid fa-gavel"></i> &nbsp; Ban</button>
							</div>
						</div>
					</div>
				</div>
			</div>
        </body>

		<script>
			var users = [];
			var users_by_id = {};
			var current_user = null;

			function escape(str) {
				return $("<div>").text(str).html();
			}

			function format_date(iso_str) {
				return moment(iso_str).format('YYYY-MM-DD HH:mm');
			}

			function load_data(new_data) {
				users = new_data;
				users_by_id = {};
				
				new_data.forEach(function(user) {
					users_by_id[user.id] = user;
				});

				generate_user_list() 
			}

			function generate_user_list() {
				$('#user_list').html('');

				var filter = null;

				if ($('#user_search').val()) {
					filter = $('#user_search').val().toLowerCase();
				}

				var ids = [];

				users.forEach(function(user) {
					var activity = user.activities[0];

					if (activity == null) { return; }

					if (filter != null) {
						if (activity.extra.Nickname.toLowerCase().indexOf(filter) == -1 && user.username.toLowerCase().indexOf(filter) == -1) {
							return;
						}
					}

					var color = 'black';
					if (user.memberships.length > 0) {
						color = user.memberships[0].group.color;
					}

					var warn_badge_color = ((user.warnings.length == 0) ? '#eee' : "#f0ad4e");
					var ban_badge_color = ((user.bans.length == 0) ? '#eee' : "#d9534f");

					$('#user_list').append(' \
					<li class="user-tab" id="user_tab_' + user.id + '" onclick="generate_user_overview(\'' + user.id + '\')" style="cursor:pointer; color: ' + color + ';"> \
						' + escape(activity.extra.Nickname) + ' \
						<span class="badge pull-right" style="background-color: ' + ban_badge_color + ';">' + user.bans.length + ' <i class="fa-solid fa-gavel"></i></span> \
						<span class="badge pull-right" style="background-color: ' + warn_badge_color + '; margin-left: 3px; margin-right: 3px;">' + user.warnings.length + ' <i class="fa-solid fa-triangle-exclamation"></i></span> \
					</li> \
					');

					ids.push(user.id);
				});

				if (ids.length == 1) {
					generate_user_overview(ids[0]);
				} else if (ids.length == 0) {
					$('#user_content_empty').show();
					$('#user_content').hide();
				}
			}

			function generate_user_overview(user_id) {
				current_user = null;

				$('#user_content_empty').hide();
				$('#user_content').hide();

				var user = users_by_id[user_id];
				if (user == null) {	return; }

				var activity = user.activities[0];
				if (activity == null) { return; }

				current_user = user;

				$('#user_content_name').text(activity.extra.Nickname);
				$('#user_content_username').text(user.username);

				$('.user-tab').removeClass("active");
				$('#user_tab_' + user_id).addClass("active");

				$('#user_content_warnings').html('');
				user.warnings.forEach(function(warning) {
					var row_class = "success";

					if (warning.disabled) {
						row_class = "active";
					} else if (!warning.active) {
						row_class = "warning";
					}

					$('#user_content_warnings').append(' \
						<tr> \
							<td class="' + row_class + '"></td> \
							<td>' + escape(warning.reason) + '</td> \
							<td>' + escape(warning.creator.username) + '</td> \
							<td>' + format_date(warning.created_on) + '</td> \
							<td class="text-right"> \
								<button class="btn btn-default btn-xs" onclick="vyhub.warning_toggle(\'' + warning.id + '\')"><i class="fa-solid fa-play"></i><i class="fa-solid fa-pause"></i></button> \
								<button class="btn btn-default btn-xs" onclick="vyhub.warning_delete(\'' + warning.id + '\')"><i class="fa-solid fa-trash"></i></button> \
							</td> \
						</tr> \
					');
				});

				$('#user_content_bans').html('');
				user.bans.forEach(function(ban) {
					var minutes = '∞';

					if (ban.length != null) {
						minutes = Math.round(ban.length/60);
					}

					var row_class = "success";

					if (ban.status == "UNBANNED") {
						row_class = "warning";
					} else if (!ban.active) {
						row_class = "danger";
					} else if (ban.serverbundle == null) {
						row_class = "info";
					}

					var actions = "";

					if (ban.status == "ACTIVE") {
						actions += '<button class="btn btn-default btn-xs" onclick="vyhub.ban_set_status(\'' + ban.id + '\', \'UNBANNED\')"><i class="fa-solid fa-check"></i> &nbsp;Unban</button>';
					} else if (ban.status == "UNBANNED") {
						actions += '<button class="btn btn-default btn-xs" onclick="vyhub.ban_set_status(\'' + ban.id + '\', \'ACTIVE\')"><i class="fa-solid fa-gavel"></i> &nbsp;Reban</button>';
					}

					$('#user_content_bans').append(' \
						<tr> \
							<td class="' + row_class + '"></td> \
							<td>' + escape(ban.reason) + '</td> \
							<td>' + escape(ban.creator.username) + '</td> \
							<td>' + format_date(ban.created_on) + '</td> \
							<td>' + minutes + '</td> \
							<td class="text-right">' + actions + '</td> \
						</tr> \
					');
				});

				$('#user_memberships').html('');

				user.memberships.forEach(function(membership) {
					$('#user_memberships').append('<span class="label label-default" style="background-color: ' + membership.group.color + ';">' + membership.group.name + '</span>');
				});

				$('#user_content').show();
			}

			function reload_current_user() {
				if (current_user != null) {
					generate_user_overview(current_user.id);
				}
			}

			function create_warning() {
				if (current_user == null) {
					return;
				}

				var reason = $('#user_warn').val();

				vyhub.warning_create(current_user.identifier, reason);

				$('#user_warn').val('');
			}

			function create_ban() {
				if (current_user == null) {
					return;
				}

				var reason = $('#user_ban_reason').val();
				var minutes = $('#user_ban_minutes').val();

				vyhub.ban_create(current_user.identifier, minutes, reason);

				$('#user_ban_reason').val('');
				$('#user_ban_minutes').val('');
			}
		</script>
    </html>
]]


function VyHub.Dashboard:load_users(users_json) 
	VyHub.Dashboard.ui_html:RunJavascript("load_data(" .. users_json .. ");")
	VyHub.Dashboard.ui_html:RunJavascript("reload_current_user();")
end

concommand.Add("vh_dashboard", function ()
	--if VyHub.Dashboard.ui == nil then
		VyHub.Dashboard:create_ui()
	--end
	VyHub.Dashboard.ui:Show()
	VyHub.Dashboard.ui:MakePopup()

	net.Start("vyhub_dashboard")
	net.SendToServer()

	if VyHub.Dashboard.ui:IsVisible() then
	--	VyHub.Dashboard.ui:Hide()
	else
	--	VyHub.Dashboard.ui:Show()
	--	VyHub.Dashboard.ui:MakePopup()
	end
end)


net.Receive("vyhub_dashboard", function()
	local data_length = net.ReadUInt(16)
	local data_raw = net.ReadData(data_length)
	local users_json = util.Decompress(data_raw)

	MsgN("Received dashboard data: " .. users_json)

	timer.Create("vyhub_dashboard_html_ready", 0.3, 20, function ()
		if not VyHub.Dashboard.html_ready then
			MsgN("VyHub Dashboard: Waiting for HTML to load.")
			return
		end

		timer.Remove("vyhub_dashboard_html_ready")

		MsgN("VyHub Dashboard: HTML Loaded")

		VyHub.Dashboard:load_users(users_json)
	end)
end)



net.Receive("vyhub_dashboard_reload", function()
	if VyHub.Dashboard.ui:IsVisible() then
		MsgN("Reloading dashboard data, because server told us.")
		net.Start("vyhub_dashboard")
		net.SendToServer()
	end
end)