<div class="offset3 span6" id="loginModal">
    <div class="modal-body">
        <div class="well">
            <div id="myTabContent" class="tab-content">
                <div class="tab-pane active in" id="login">
                    <form class="form-horizontal" action="/login.html" method="POST">
                        <input type='hidden' name="returnUrl" value="{xdmp:get-request-field("returnUrl")}"/>
                        <fieldset>
                            <div id="legend">
                                <legend class="">Login</legend>
                            </div>
                                <?if response:flash("login")?>
                                    <div class="alert alert-error">
                                        <a class="close" data-dismiss="alert" href="#">x</a>Incorrect Username or Password!
                                    </div> 
                               <?endif?>
                            <div class="control-group">
                                <!-- Username -->
                                <label class="control-label" for="username">Username</label>
                                <div class="controls">
                                    <input type="text" id="username" name="username" placeholder="" class="input-xlarge"/>
                                </div>
                            </div>
                            <div class="control-group">
                                <!-- Password-->
                                <label class="control-label" for="password">Password</label>
                                <div class="controls">
                                    <input type="password" id="password" name="password" placeholder="" class="input-xlarge"/>
                                </div>
                            </div>
                            <div class="control-group">
                                <!-- Button -->
                                <div class="controls">
                                    <button class="btn btn-primary">Login</button>
                                </div>
                            </div>
                        </fieldset>
                    </form>
                </div>
                <div class="tab-pane fade" id="create">
                    <form id="tab">
                        <label>Username</label>
                        <input type="text" value="" class="input-xlarge"/>
                        <label>First Name</label>
                        <input type="text" value="" class="input-xlarge"/>
                        <label>Last Name</label>
                        <input type="text" value="" class="input-xlarge"/>
                        <label>Email</label>
                        <input type="text" value="" class="input-xlarge"/>
                        <label>Address</label>
                        <textarea value="Smith" rows="3" class="input-xlarge"> </textarea>
                        <div>
                            <button class="btn btn-primary">Create Account</button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</div>
