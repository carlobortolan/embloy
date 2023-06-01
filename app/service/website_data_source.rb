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
</div>
`'
  end

end
