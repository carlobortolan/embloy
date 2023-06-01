# frozen_string_literal: true

class WebsiteDataSource
  def self.page_b2b
    'document.querySelector(\'#app\').innerHTML = `
<div class="ext_base">
    <div style="background-color: white; height: 4px; width: 100%; border-radius: 100%; margin-bottom: 80px;"></div>
    <h1 class="ext_bigsubtop" style="width:100%;text-align: left;">Our audience is flexible, young and always
        reachable.</h1>
    <div class="ext_aa">
        <div class="ext_ba">
            <h1 class="ext_bigtop" style="margin-bottom: -5px; text-align: left;">$84bn</h1>
            <p style="font-size: 15pt; font-family: \'Figtree\'; font-weight: 400; color: white; text-align: left;">
                BCG estimates that the shortage of workers costs the German economy 84,000,000,000 USD annually.</p>
        </div>
        <div class="ext_ca"></div>
        <div class="ext_ba">
            <h1 class="ext_bigtop" style="margin-bottom: -5px; text-align: left;">~53%</h1>
            <p style="font-size: 15pt; font-family: \'Figtree\'; font-weight: 400; color: white; text-align: left;">
                More than half of the urban young-adult population reports being online almost constantly.</p>
        </div>
        <div class="ext_ca"></div>
        <div class="ext_ba">
            <h1 class="ext_bigtop" style="margin-bottom: -5px; text-align: left;">10 min</h1>
            <p style="font-size: 15pt; font-family: \'Figtree\'; font-weight: 400; color: white; text-align: left;">
                It takes less than 10 minutes to sign up to Embloy and start hiring.</p>
        </div>
    </div>
    <div style="background-color: white; height: 4px; width: 100%; border-radius: 100%; margin-top: 80px;"></div>
    <div class="ext_base" style="height:150px;"></div>
    <div class="ext_base" style="height:450px; max-width: 1000px;">
        <div class="ext_subbase" style="width: 100%; z-index: 1; margin-top: 30px; justify-content: center;">
            <img id="banner" class="ext_banner" src="http://localhost:5173/src/assets/banner_4.png">
            <div class="ext_base" style="height: 100%; justify-content: center;" data-aos="fade-up"
                 data-aos-delay="200">


                <div class="ext_base ext_da">
                    <div class="ext_base ext_ea"></div>
                    <div class="ext_fa">
                        <h1 class="ext_bigtop_2 ext_ga">I want to:</h1>
                    </div>
                </div>


                <div class="ext_base ext_ha">
                    <div class="ext_base ext_ia"></div>

                    <div class="ext_ja">
                        <div class="ext_base ext_ka"></div>
                        <h1 class="ext_bigsubtop ext_la">Hire with Embloy</h1>
                        <div class="ext_base ext_ma">
                            <img src="http://localhost:5173/src/assets/arrow_right_circle.svg"
                                 class="ext_info-button ext_na">
                        </div>
                    </div>

                    <div class="ext_base ext_oa"></div>

                    <div class="ext_ja">
                        <div class="ext_base ext_ka"></div>
                        <h1 class="ext_bigsubtop ext_la">Improve my online presence</h1>
                        <div class="ext_base ext_ma">
                            <img src="http://localhost:5173/src/assets/arrow_right_circle.svg"
                                 class="ext_info-button ext_na">
                        </div>
                    </div>

                    <div class="ext_base ext_oa"></div>

                    <div class="ext_ja">
                        <div class="ext_base ext_ka"></div>
                        <h1 class="ext_bigsubtop ext_la">Advertise on Embloy</h1>
                        <div class="ext_base ext_ma">
                            <img src="http://localhost:5173/src/assets/arrow_right_circle.svg"
                                 class="ext_info-button ext_na">
                        </div>
                    </div>

                    <div class="ext_base ext_ia"></div>
                </div>
            </div>
        </div>
    </div>
    <div class="ext_base" style="height:250px;"></div>
    <div class="ext_base ext_pa">
       <div class="ext_base ext_qa">
          <h1 class="ext_bigtop" style="width:100%; text-align:left; font-weight:900;">Let everybody know who you are</h1>
      </div>
      <div class="ext_base ext_qa">
          <h1 class="ext_bigsubtop" style="width:100%; text-align:left; font-weight:900;">Embloy helps you to grow your workforce pool.</h1>
      </div>
      <div class="ext_base" style="height:100px;"></div>
      <div class="ext_base ext_ra">
        <div class="ext_base ext_sa">
          <img src="http://localhost:5173/src/assets/websitebanner_12.png" style="width:auto; height:750px">
        </div>
        <div class="ext_ta">


          <div class="ext_ua">
            <h1 class="ext_bigsubtop ext_va">Last minute? No problem</h1>
            <p class="ext_wa">Quickly hire people to fill in short-term staff shortages. Like for your usual take out delivery you\'ll be served on time.</p>
          </div>

          <div class="ext_ua">
            <h1 class="ext_bigsubtop ext_va">It\'s a match!</h1>
            <p class="ext_wa">Trust in online dating to get a good date? Trust us to set you up with the best staff for your specific open position.</p>
          </div>

          <div class="ext_ua">
            <h1 class="ext_bigsubtop ext_va">Be organized</h1>
            <p class="ext_wa">Keep track of working hours, stay in direct contact to former employees and claim specific tax and financial documents.</p>
          </div>

          <div class="ext_ua">
            <h1 class="ext_bigsubtop ext_va">Boost your productivity</h1>
            <p class="ext_wa">Hire & Fire with one click. Say good-bye to time consuming back and forth via Email and phone.</p>
          </div>

          <div class="ext_ua ext_xa">
            <div class="ext_button-styles" onclick="linkTo(\"https://test.com\")">
	             <p class="ext_txt">Learn about the Embloy platform</p>
            </div>
          </div>

        </div>
      </div>
    </div>
</div>
`'
  end

end
