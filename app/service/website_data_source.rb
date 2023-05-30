# frozen_string_literal: true

class WebsiteDataSource
  def self.page_b2b
    'document.querySelector(\'#app\').innerHTML = `
<h1 class="ext_bigsubtop" style="width:100%;text-align: left;">Our audience is flexible, young and always reachable.</h1>
<div class="ext_aa">
	<div class="ext_ba">
		<h1 class="ext_bigtop" style="margin-bottom: -5px; text-align: left;">$84bn</h1>
		<p style="font-size: 15pt; font-family: \'Kumbh Sans\'; font-weight: 400; color: white; text-align: left;">BCG estimates that the shortage of workers costs the German economy 84,000,000,000 USD annually.</p>
	</div>
	<div class="ext_ca"></div>
	<div class="ext_ba">
		<h1 class="ext_bigtop" style="margin-bottom: -5px; text-align: left;">~53%</h1>
		<p style="font-size: 15pt; font-family: \'Kumbh Sans\'; font-weight: 400; color: white; text-align: left;">More than half of the urban young-adult population reports being online almost constantly.</p>
	</div>
	<div class="ext_ca"></div>
	<div class="ext_ba">
		<h1 class="ext_bigtop" style="margin-bottom: -5px; text-align: left;">10 min</h1>
		<p style="font-size: 15pt; font-family: \'Kumbh Sans\'; font-weight: 400; color: white; text-align: left;">It takes less than 10 minutes to sign up to Embloy and start hiring.</p>
	</div>
</div>
`'
  end

end
