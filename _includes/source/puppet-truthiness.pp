$fednu = undef
$eslaf = false
$lambda = ''
$empty_array = []
$hiera_undef = hiera('nevergonnagiveyouup', undef)
#$no_such_var

notice("* Checking for truthiness in ERB *")
notice("")
notice(inline_template("<%= if @fednu; '@fednu is truthy'; else '@fednu is not truthy'; end %>"))
notice(inline_template("<%= if @eslaf; '@eslaf is truthy'; else '@eslaf is not truthy'; end %>"))
warning(inline_template("<%= if @lambda; '@lambda is truthy'; else '@lambda is not truthy'; end %>"))
warning(inline_template("<%= if @empty_array; '@empty_array is truthy'; else '@empty_array is not truthy'; end %>"))
warning(inline_template("<%= if @hiera_undef; '@hiera_undef is truthy'; else '@hiera_undef is not truthy'; end %>"))
notice(inline_template("<%= if @no_such_var; '@no_such_var is truthy'; else '@no_such_var is not truthy'; end %>"))

notice("")
notice("* Checking for truthiness in Puppet lang *")
notice("")

if $fednu { notice('$fednu is truthy') } else { notice('$fednu is not truthy') }
if $eslaf { notice('$eslaf is truthy') } else { notice('$eslaf is not truthy') }
if $lambda { notice('$lambda is truthy') } else { notice('$lambda is not truthy') }
if $empty_array { notice('$empty_array is truthy') } else { notice('$empty_array is not truthy') }
if $hiera_undef { notice('$hiera_undef is truthy') } else { notice('$hiera_undef is not truthy') }
if $no_such_var { notice('$no_such_var is truthy') } else { notice('$no_such_var is not truthy') }

notice("")
notice("* Checking for nil *")
notice("")
notice(inline_template("<%= if @fednu.nil?; '@fednu is nil'; else '@fednu is not nil'; end %>"))
notice(inline_template("<%= if @eslaf.nil?; '@eslaf is nil'; else '@eslaf is not nil'; end %>"))
notice(inline_template("<%= if @lambda.nil?; '@lambda is nil'; else '@lambda is not nil'; end %>"))
notice(inline_template("<%= if @empty_array.nil?; '@empty_array is nil'; else '@empty_array is not nil'; end %>"))
notice(inline_template("<%= if @hiera_undef.nil?; '@hiera_undef is nil'; else '@hiera_undef is not nil'; end %>"))
notice(inline_template("<%= if @no_such_var.nil?; '@no_such_var is nil'; else '@no_such_var is not nil'; end %>"))

notice("")
notice("* Checking rendering in ERB *")
notice("")
notice(inline_template("@fednu is '<%= @fednu.to_s %>'"))
notice(inline_template("@eslaf is '<%= @eslaf.to_s %>'"))
notice(inline_template("@lambda is '<%= @lambda.to_s %>'"))
notice(inline_template("@empty_array is '<%= @empty_array.to_s %>'"))
notice(inline_template("@hiera_undef is '<%= @hiera_undef.to_s %>'"))
notice(inline_template("@no_such_var is '<%= @no_such_var.to_s %>'"))

notice("")
notice("* Checking rendering in Puppet lang *")
notice("")
notice("\$fednu is '${fednu}'")
notice("\$eslaf is '${eslaf}'")
notice("\$lambda is '${lambda}'")
notice("\$empty_array is '${empty_array}'")
notice("\$hiera_undef is '${hiera_undef}'")
notice("\$no_such_var is '${no_such_var}'")


notice("")
notice("DONE")

